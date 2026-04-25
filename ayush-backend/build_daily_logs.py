import asyncio
import sys
from datetime import datetime, timezone, timedelta
from collections import defaultdict
from motor.motor_asyncio import AsyncIOMotorClient
 
# ─────────────────────────────────────────────────────────────────────────────
# CONFIG — edit these if your settings module path differs
# ─────────────────────────────────────────────────────────────────────────────
try:
    from config.settings import settings
    MONGO_URL = settings.mongodb_url
    DB_NAME   = settings.mongodb_db_name
except Exception:
    # Fallback: set directly if import fails
    MONGO_URL = "mongodb://localhost:27017"
    DB_NAME   = "ayush"
 
# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL COLORS (no dependencies)
# ─────────────────────────────────────────────────────────────────────────────
class C:
    HEADER  = "\033[95m"
    BLUE    = "\033[94m"
    CYAN    = "\033[96m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    RED     = "\033[91m"
    BOLD    = "\033[1m"
    DIM     = "\033[2m"
    RESET   = "\033[0m"
 
def _h(text):  print(f"\n{C.BOLD}{C.HEADER}{'═'*60}{C.RESET}");\
               print(f"{C.BOLD}{C.HEADER}  {text}{C.RESET}");\
               print(f"{C.BOLD}{C.HEADER}{'═'*60}{C.RESET}")
def _ok(msg):  print(f"  {C.GREEN}✔  {msg}{C.RESET}")
def _warn(msg):print(f"  {C.YELLOW}⚠  {msg}{C.RESET}")
def _err(msg): print(f"  {C.RED}✘  {msg}{C.RESET}")
def _info(msg):print(f"  {C.CYAN}→  {msg}{C.RESET}")
def _kv(k, v): print(f"  {C.DIM}{k:<28}{C.RESET}{C.BOLD}{v}{C.RESET}")
 
# ─────────────────────────────────────────────────────────────────────────────
# FEATURE DERIVATION HELPERS
# Maps your actual DB field values → clean numeric LSTM features
# ─────────────────────────────────────────────────────────────────────────────
 
def derive_tongue_coating(coating_score: float) -> float:
    """
    coating_score (0–100 raw) → tongue_coating (0.0–5.0)
    0  = no coating (clean)
    5  = very heavy coating (high ama)
    """
    return round(min(5.0, coating_score / 20.0), 2)
 
 
def derive_tongue_color(color_classification: str) -> float:
    """
    color_classification string → tongue_color (0.0–3.0)
    0 = pink_healthy
    1 = pale
    2 = red/inflamed
    3 = dark/severe
    """
    mapping = {
        "pink_healthy": 0.0,
        "pink":         0.0,
        "pale":         1.0,
        "pale_white":   1.0,
        "white":        1.0,
        "red":          2.0,
        "red_inflamed": 2.0,
        "inflamed":     2.0,
        "dark":         3.0,
        "purple":       3.0,
        "brown":        3.0,
    }
    key = color_classification.lower().strip()
    return mapping.get(key, 1.0)  # default: pale (neutral)
 
 
def derive_eye_redness(redness_index: float, redness_classification: str) -> float:
    """
    redness_index (0–100 raw) + classification → eye_redness (0.0–5.0)
    """
    classification_bump = {
        "clear":    0.0,
        "mild":     0.5,
        "moderate": 1.0,
        "severe":   2.0,
    }
    base  = round(min(5.0, redness_index / 20.0), 2)
    bump  = classification_bump.get(redness_classification.lower(), 0.0)
    return round(min(5.0, base + bump), 2)
 
 
def derive_sleep_quality(ojas_breakdown: dict) -> float:
    """
    Extracts sleep bonus from ojasBreakdown.bonuses list → sleep_quality (1–10)
    If 'sleep' bonus exists → good sleep signal
    """
    bonuses = ojas_breakdown.get("bonuses", [])
    for bonus in bonuses:
        reason = bonus.get("reason", "").lower()
        if "sleep" in reason:
            val = bonus.get("value", 0)
            if val >= 4:
                return 8.0   # healthy sleep bonus
            elif val >= 2:
                return 6.0
            else:
                return 4.0
    # No sleep bonus found → neutral
    return 5.0
 
 
def derive_stress_level(nadi_entries: list) -> float:
    """
    From nadiHistory entries for the day:
    - Vata-dominant + low confidence → high stress
    - Pitta-dominant → moderate stress
    - Kapha-dominant → low stress
    Returns stress_level (1–10)
    """
    if not nadi_entries:
        return 5.0  # neutral default
 
    dosha_map = {0: "Vata", 1: "Pitta", 2: "Kapha"}
    # Take the most recent entry with highest confidence
    best = max(nadi_entries, key=lambda x: x.get("confidence", 0))
 
    dominant = best.get("dominantDosha", 1)
    confidence = best.get("confidence", 50)
 
    stress_base = {0: 7.0, 1: 5.0, 2: 3.0}  # Vata=stressed, Kapha=calm
    base = stress_base.get(dominant, 5.0)
 
    # Low confidence = uncertain reading = moderate stress
    if confidence < 30:
        return round((base + 5.0) / 2, 1)
 
    return base
 
 
def derive_energy_level(ojas_score: float, tongue_coating: float, eye_redness: float) -> float:
    """
    Composite energy from ojas (main driver) + tongue/eye signals.
    Returns energy_level (1–10)
    """
    # ojas 0-100 → 1-10 scale
    ojas_energy = round((ojas_score / 100) * 10, 1)
 
    # Penalties from tongue and eye
    coating_penalty = tongue_coating * 0.3     # max ~1.5 deduction
    redness_penalty = eye_redness  * 0.2       # max ~1.0 deduction
 
    energy = ojas_energy - coating_penalty - redness_penalty
    return round(max(1.0, min(10.0, energy)), 2)
 
 
def derive_food_quality_score(food_logs_for_day: list) -> tuple:
    """
    From food_logs documents for a single day:
    Returns (food_quality_score 0-100, viruddha_violations int)
    food_quality = average of (50 + totalOjasDelta) per log, clamped 0-100
    """
    if not food_logs_for_day:
        return 50.0, 0  # neutral defaults
 
    quality_sum      = 0.0
    total_viruddha   = 0
 
    for log in food_logs_for_day:
        ojas_delta  = log.get("totalOjasDelta", 0)
        quality_sum += max(0.0, min(100.0, 50.0 + ojas_delta))
        total_viruddha += len(log.get("viruddhaWarnings", []))
 
    avg_quality = round(quality_sum / len(food_logs_for_day), 1)
    return avg_quality, total_viruddha
 
 
# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1 — VERIFY SOURCE COLLECTIONS
# ─────────────────────────────────────────────────────────────────────────────
 
async def phase1_verify_collections(db, user_id: str):
    _h("PHASE 1 — VERIFYING SOURCE COLLECTIONS")
 
    required = {
        "users":           "Core user profile (ojas, prakriti, nadi)",
        "food_logs":       "Daily food scan results (ojas_delta, viruddha)",
        "tongue_captures": "Tongue analysis per day",
        "eye_captures":    "Eye analysis per day",
    }
    optional = {
        "food_history":    "Detailed food analysis (backup source)",
        "food_feedback":   "User meal feedback",
        "recipes":         "Saved recipes",
    }
 
    all_collections = await db.list_collection_names()
    issues = []
 
    for coll, desc in required.items():
        if coll not in all_collections:
            _err(f"{coll:<20} MISSING  — {desc}")
            issues.append(coll)
        else:
            count = await db[coll].count_documents({"$or": [
                {"userId": user_id}, {"user_id": user_id}
            ]})
            if count == 0:
                _warn(f"{coll:<20} EXISTS but 0 docs for this user — {desc}")
            else:
                _ok(f"{coll:<20} {count} doc(s) — {desc}")
 
    for coll, desc in optional.items():
        if coll in all_collections:
            count = await db[coll].count_documents({"$or": [
                {"userId": user_id}, {"user_id": user_id}
            ]})
            _info(f"{coll:<20} {count} doc(s) — {desc}")
 
    if issues:
        _err(f"\nFATAL: {len(issues)} required collection(s) missing: {issues}")
        _err("Cannot build daily_logs without these. Fix your API routes first.")
        sys.exit(1)
 
    _ok("All required collections verified.")
    return True

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2 — INSPECT AND VALIDATE SCHEMA
# ─────────────────────────────────────────────────────────────────────────────
 
async def phase2_validate_schema(db, user_id: str):
    _h("PHASE 2 — VALIDATING DOCUMENT SCHEMAS")
 
    user = await db["users"].find_one({"userId": user_id})
    if not user:
        _err("User document not found. Cannot proceed.")
        sys.exit(1)
 
    # Validate user document
    user_checks = {
        "ojasScore":      user.get("ojasScore"),
        "ojasBreakdown":  user.get("ojasBreakdown"),
        "nadiHistory":    user.get("nadiHistory"),
        "prakritiResult": user.get("prakritiResult"),
    }
    print(f"\n  {C.BOLD}[ users ]{C.RESET}")
    for field, val in user_checks.items():
        if val is None:
            _warn(f"{field:<24} MISSING — will use default")
        elif isinstance(val, list):
            _ok(f"{field:<24} list with {len(val)} entries")
        elif isinstance(val, dict):
            _ok(f"{field:<24} dict with keys: {list(val.keys())[:4]}")
        else:
            _ok(f"{field:<24} = {val}")
 
    # Validate food_logs
    print(f"\n  {C.BOLD}[ food_logs ]{C.RESET}")
    async for doc in db["food_logs"].find({"userId": user_id}):
        required_fields = ["totalOjasDelta", "viruddhaWarnings", "loggedAt"]
        for field in required_fields:
            if field not in doc:
                _warn(f"food_logs doc missing field: {field}")
            else:
                _ok(f"{field:<24} ✔")
        break  # validate schema from first doc only
 
    # Validate tongue_captures
    print(f"\n  {C.BOLD}[ tongue_captures ]{C.RESET}")
    tongue_doc = await db["tongue_captures"].find_one({"userId": user_id})
    if tongue_doc:
        for field in ["coating_score", "color_classification", "tongue_health_score", "date_key"]:
            if field not in tongue_doc:
                _warn(f"tongue_captures missing: {field}")
            else:
                _ok(f"{field:<24} = {tongue_doc[field]}")
    else:
        _warn("No tongue_captures found for this user")
 
    # Validate eye_captures
    print(f"\n  {C.BOLD}[ eye_captures ]{C.RESET}")
    eye_doc = await db["eye_captures"].find_one({"userId": user_id})
    if eye_doc:
        for field in ["redness_index", "redness_classification", "eye_health_score", "date_key"]:
            if field not in eye_doc:
                _warn(f"eye_captures missing: {field}")
            else:
                _ok(f"{field:<24} = {eye_doc[field]}")
    else:
        _warn("No eye_captures found for this user")
 
    _ok("\nSchema validation complete.")
    return user

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3 — BUILD DAILY LOGS (12-FEATURE AGGREGATION)
# ─────────────────────────────────────────────────────────────────────────────
 
async def phase3_build_daily_logs(db, user_id: str, user_doc: dict):
    _h("PHASE 3 — AGGREGATING 12-FEATURE DAILY LOGS")
 
    # ── Gather all dated source data ──────────────────────────────────────────
 
    # 1. food_logs grouped by date
    food_by_date = defaultdict(list)
    async for doc in db["food_logs"].find({"userId": user_id}):
        logged_at = doc.get("loggedAt")
        if logged_at:
            date_key = logged_at.date().isoformat() if isinstance(logged_at, datetime) \
                       else str(logged_at)[:10]
            food_by_date[date_key].append(doc)
 
    # 2. tongue_captures by date
    tongue_by_date = {}
    async for doc in db["tongue_captures"].find({"userId": user_id}):
        tongue_by_date[doc.get("date_key", str(doc.get("timestamp", ""))[:10])] = doc
 
    # 3. eye_captures by date
    eye_by_date = {}
    async for doc in db["eye_captures"].find({"userId": user_id}):
        eye_by_date[doc.get("date_key", str(doc.get("timestamp", ""))[:10])] = doc
 
    # 4. nadiHistory from user doc — group by date
    nadi_by_date = defaultdict(list)
    for entry in (user_doc.get("nadiHistory") or []):
        ts = entry.get("timestamp")
        if ts:
            date_key = ts.date().isoformat() if isinstance(ts, datetime) \
                       else str(ts)[:10]
            nadi_by_date[date_key].append(entry)
 
    # ── Determine all dates that have ANY data ────────────────────────────────
    all_dates = set(food_by_date.keys()) | set(tongue_by_date.keys()) | \
                set(eye_by_date.keys())  | set(nadi_by_date.keys())
 
    if not all_dates:
        _err("No dated data found across any source collection.")
        _err("User needs to use the app first: food scan, tongue/eye capture, nadi check.")
        sys.exit(1)
 
    _info(f"Found data across {len(all_dates)} unique date(s): {sorted(all_dates)}")
 
    # ── Static values from user profile (same for all days) ──────────────────
    ojas_score    = float(user_doc.get("ojasScore", 50))
    ojas_breakdown= user_doc.get("ojasBreakdown", {})
    sleep_quality = derive_sleep_quality(ojas_breakdown)
 
    # ── Build one daily_log per date ──────────────────────────────────────────
    built_count   = 0
    skipped_count = 0
 
    for date_key in sorted(all_dates):
        food_logs   = food_by_date.get(date_key, [])
        tongue_doc  = tongue_by_date.get(date_key)
        eye_doc     = eye_by_date.get(date_key)
        nadi_entries= nadi_by_date.get(date_key, [])
 
        # ── Derive each feature ───────────────────────────────────────────────
        food_quality, viruddha_count = derive_food_quality_score(food_logs)
 
        # Tongue features
        if tongue_doc:
            tongue_coating = derive_tongue_coating(tongue_doc.get("coating_score", 50))
            tongue_color   = derive_tongue_color(tongue_doc.get("color_classification", "pale"))
        else:
            tongue_coating = 2.5   # neutral: moderate coating
            tongue_color   = 1.0   # neutral: pale
 
        # Eye features
        if eye_doc:
            eye_redness = derive_eye_redness(
                eye_doc.get("redness_index", 20),
                eye_doc.get("redness_classification", "mild")
            )
        else:
            eye_redness = 1.0  # neutral
 
        # Heart rate from nadi (BPM field in nadiHistory)
        if nadi_entries:
            best_nadi   = max(nadi_entries, key=lambda x: x.get("confidence", 0))
            heart_rate  = round(float(best_nadi.get("bpm", 72.0)), 1)
        else:
            heart_rate  = 72.0  # neutral resting HR
 
        # Stress from nadi dominance
        stress_level  = derive_stress_level(nadi_entries)
 
        # Energy is composite
        energy_level  = derive_energy_level(ojas_score, tongue_coating, eye_redness)
 
        # Yoga: not yet stored in DB — default to 0 (honest)
        yoga_done     = 0
        yoga_accuracy = 0.0
 
        # ── Final 12-feature vector ───────────────────────────────────────────
        features = {
            "food_quality_score":     food_quality,      # 0–100
            "viruddha_violations":    viruddha_count,    # int
            "yoga_done":              yoga_done,          # 0 or 1
            "yoga_accuracy_percent":  yoga_accuracy,      # 0–100
            "ojas_score":             round(ojas_score, 1),# 0–100
            "tongue_coating":         tongue_coating,     # 0–5
            "tongue_color":           tongue_color,       # 0–3
            "eye_redness":            eye_redness,        # 0–5
            "heart_rate_bpm":         heart_rate,         # numeric BPM
            "sleep_quality":          sleep_quality,      # 1–10
            "stress_level":           stress_level,       # 1–10
            "energy_level":           energy_level,       # 1–10
        }
 
        # ── Data source audit (what was available vs defaulted) ───────────────
        sources_used = {
            "food_logs":       len(food_logs) > 0,
            "tongue_captures": tongue_doc is not None,
            "eye_captures":    eye_doc is not None,
            "nadi_history":    len(nadi_entries) > 0,
        }
 
        # ── Upsert into daily_logs collection ─────────────────────────────────
        now = datetime.now(timezone.utc)
        result = await db["daily_logs"].update_one(
            {"userId": user_id, "date": date_key},
            {
                "$set": {
                    "userId":       user_id,
                    "date":         date_key,
                    "features":     features,
                    "sources_used": sources_used,
                    "consolidated": True,
                    "schema_version": "1.0",
                    "updated_at":   now,
                },
                "$setOnInsert": {
                    "created_at": now,
                }
            },
            upsert=True
        )
 
        if result.upserted_id:
            _ok(f"CREATED  daily_log for {date_key}")
            built_count += 1
        elif result.modified_count:
            _ok(f"UPDATED  daily_log for {date_key}")
            built_count += 1
        else:
            _warn(f"UNCHANGED daily_log for {date_key} (already up to date)")
            skipped_count += 1
 
        # Show what was used vs defaulted
        missing = [k for k, v in sources_used.items() if not v]
        if missing:
            _warn(f"  Defaulted: {missing} (no data for {date_key})")
 
    print()
    _ok(f"Built/updated {built_count} daily_log(s). Skipped {skipped_count} (unchanged).")
    return sorted(all_dates)

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 4 — CONFIRM: READ BACK AND DISPLAY
# ─────────────────────────────────────────────────────────────────────────────
 
async def phase4_confirm_output(db, user_id: str, dates: list):
    _h("PHASE 4 — CONFIRMING WRITTEN DAILY LOGS")
 
    total_docs = await db["daily_logs"].count_documents({"userId": user_id})
    _info(f"Total daily_logs for this user: {total_docs}")
 
    if total_docs == 0:
        _err("Nothing was written. Something went wrong in Phase 3.")
        return
 
    if total_docs < 7:
        _warn(f"Only {total_docs}/7 days of data. LSTM needs at least 7 consecutive days.")
        _warn("Keep using the app daily. Run this script each day to accumulate data.")
    else:
        _ok(f"{total_docs} days available — enough to feed the LSTM.")
 
    print()
    print(f"  {C.BOLD}{'DATE':<14}{'FOOD_Q':>7}{'VIRUD':>7}{'YOGA':>6}{'OJAS':>7}{'COAT':>7}{'COLOR':>7}{'EYE':>7}{'HR':>7}{'SLEEP':>7}{'STRESS':>8}{'ENERGY':>8}{C.RESET}")
    print(f"  {'─'*96}")
 
    async for doc in db["daily_logs"].find({"userId": user_id}).sort("date", 1):
        f = doc.get("features", {})
        date   = doc.get("date", "?")
        src    = doc.get("sources_used", {})
        src_str= "".join([
            "F" if src.get("food_logs") else "·",
            "T" if src.get("tongue_captures") else "·",
            "E" if src.get("eye_captures") else "·",
            "N" if src.get("nadi_history") else "·",
        ])
        print(
            f"  {C.CYAN}{date}{C.RESET} [{C.YELLOW}{src_str}{C.RESET}]"
            f"  {f.get('food_quality_score',0):>6.1f}"
            f"  {f.get('viruddha_violations',0):>5}"
            f"  {f.get('yoga_done',0):>4}"
            f"  {f.get('ojas_score',0):>6.1f}"
            f"  {f.get('tongue_coating',0):>6.2f}"
            f"  {f.get('tongue_color',0):>6.1f}"
            f"  {f.get('eye_redness',0):>6.2f}"
            f"  {f.get('heart_rate_bpm',0):>6.1f}"
            f"  {f.get('sleep_quality',0):>6.1f}"
            f"  {f.get('stress_level',0):>7.1f}"
            f"  {f.get('energy_level',0):>7.2f}"
        )
 
    print()
    print(f"  {C.DIM}Sources legend: F=food_logs  T=tongue  E=eye  N=nadi  ·=defaulted{C.RESET}")
 
    # LSTM readiness check
    print()
    _h("LSTM READINESS REPORT")
 
    if total_docs >= 7:
        _ok("✔  7+ days of data — LSTM can train")
    else:
        days_needed = 7 - total_docs
        _warn(f"Need {days_needed} more day(s) of app usage to reach LSTM minimum")
 
    feature_names = [
        "food_quality_score", "viruddha_violations", "yoga_done",
        "yoga_accuracy_percent", "ojas_score", "tongue_coating",
        "tongue_color", "eye_redness", "heart_rate_bpm",
        "sleep_quality", "stress_level", "energy_level"
    ]
 
    # Audit which features are real vs defaulted across all logs
    print(f"\n  {C.BOLD}Feature completeness across {total_docs} day(s):{C.RESET}")
    feature_real_counts = defaultdict(int)
 
    async for doc in db["daily_logs"].find({"userId": user_id}):
        src = doc.get("sources_used", {})
        f   = doc.get("features", {})
        if src.get("food_logs"):
            feature_real_counts["food_quality_score"] += 1
            feature_real_counts["viruddha_violations"] += 1
        if src.get("tongue_captures"):
            feature_real_counts["tongue_coating"] += 1
            feature_real_counts["tongue_color"]   += 1
        if src.get("eye_captures"):
            feature_real_counts["eye_redness"] += 1
        if src.get("nadi_history"):
            feature_real_counts["heart_rate_bpm"] += 1
            feature_real_counts["stress_level"]   += 1
        # ojas + sleep + energy are always derived
        feature_real_counts["ojas_score"]    += 1
        feature_real_counts["sleep_quality"] += 1
        feature_real_counts["energy_level"]  += 1
        # yoga always 0 until yoga module is fixed
        # feature_real_counts["yoga_done"] stays 0
 
    for feat in feature_names:
        real  = feature_real_counts[feat]
        pct   = int((real / max(total_docs, 1)) * 100)
        bar   = ("█" * (pct // 10)).ljust(10)
        color = C.GREEN if pct >= 70 else C.YELLOW if pct >= 30 else C.RED
        print(f"  {feat:<28} {color}{bar}{C.RESET} {pct:>3}% real data")
 
    print()
    _warn("yoga_done / yoga_accuracy_percent → 0% real. Fix the yoga module to save to DB.")
    _info("Run this script daily after the user uses the app to keep daily_logs current.")
 
 
# ─────────────────────────────────────────────────────────────────────────────
# ENTRYPOINT
# ─────────────────────────────────────────────────────────────────────────────
 
async def main():
    print(f"\n{C.BOLD}{C.BLUE}  AYUSH — DAILY LOG BUILDER  v1.0{C.RESET}")
    print(f"  {C.DIM}MongoDB: {MONGO_URL}  DB: {DB_NAME}{C.RESET}")
 
    # ── Accept user_id from CLI arg or use default ────────────────────────────
    user_id = sys.argv[1] if len(sys.argv) > 1 else "5cf7d3fa-d479-43c3-850e-75e6485bb870"
    _info(f"Target user_id: {user_id}")
 
    client = AsyncIOMotorClient(MONGO_URL)
    db     = client[DB_NAME]
 
    try:
        await phase1_verify_collections(db, user_id)
        user_doc = await phase2_validate_schema(db, user_id)
        dates    = await phase3_build_daily_logs(db, user_id, user_doc)
        await phase4_confirm_output(db, user_id, dates)
 
        print(f"\n{C.BOLD}{C.GREEN}  ✔  Pipeline complete.{C.RESET}\n")
 
    except SystemExit:
        print(f"\n{C.BOLD}{C.RED}  ✘  Pipeline aborted. Fix the errors above and re-run.{C.RESET}\n")
    finally:
        client.close()
 
 
if __name__ == "__main__":
    asyncio.run(main())
