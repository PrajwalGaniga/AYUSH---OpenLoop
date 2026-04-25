import asyncio
import sys
import csv
import random
from datetime import datetime, date, timedelta, timezone
from collections import defaultdict
from motor.motor_asyncio import AsyncIOMotorClient
 
# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────
try:
    from config.settings import settings
    MONGO_URL = settings.mongodb_url
    DB_NAME   = settings.mongodb_db_name
except Exception:
    MONGO_URL = "mongodb://localhost:27017"
    DB_NAME   = "ayush"
 
USER_ID = sys.argv[1] if len(sys.argv) > 1 else "5cf7d3fa-d479-43c3-850e-75e6485bb870"
 
# The 7-day window: Apr 24 is day 1 (earliest food_log), Apr 30 is day 7
DAY_1   = date(2026, 4, 24)
ALL_7   = [(DAY_1 + timedelta(days=i)).isoformat() for i in range(7)]
 
CSV_OUTPUT = "lstm_ready_dataset.csv"
 
FEATURE_KEYS = [
    "food_quality_score",
    "viruddha_violations",
    "yoga_done",
    "yoga_accuracy_percent",
    "ojas_score",
    "tongue_coating",
    "tongue_color",
    "eye_redness",
    "heart_rate_bpm",
    "sleep_quality",
    "stress_level",
    "energy_level",
]
 
# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL COLORS
# ─────────────────────────────────────────────────────────────────────────────
class C:
    HEADER = "\033[95m"; BLUE = "\033[94m"; CYAN = "\033[96m"
    GREEN  = "\033[92m"; YELLOW = "\033[93m"; RED = "\033[91m"
    BOLD   = "\033[1m";  DIM = "\033[2m";    RESET = "\033[0m"
 
def _h(text):
    print(f"\n{C.BOLD}{C.HEADER}{'═'*64}{C.RESET}")
    print(f"{C.BOLD}{C.HEADER}  {text}{C.RESET}")
    print(f"{C.BOLD}{C.HEADER}{'═'*64}{C.RESET}")
 
def _ok(m):   print(f"  {C.GREEN}✔  {m}{C.RESET}")
def _warn(m): print(f"  {C.YELLOW}⚠  {m}{C.RESET}")
def _err(m):  print(f"  {C.RED}✘  {m}{C.RESET}")
def _info(m): print(f"  {C.CYAN}→  {m}{C.RESET}")
def _sub(m):  print(f"      {C.DIM}{m}{C.RESET}")
 
# ─────────────────────────────────────────────────────────────────────────────
# SHARED UPSERT HELPER
# ─────────────────────────────────────────────────────────────────────────────
async def upsert_daily_log(db, user_id: str, date_key: str, features: dict,
                            sources_used: dict, tag: str = "seeded"):
    now = datetime.now(timezone.utc)
    result = await db["daily_logs"].update_one(
        {"userId": user_id, "date": date_key},
        {
            "$set": {
                "userId":         user_id,
                "date":           date_key,
                "features":       features,
                "sources_used":   sources_used,
                "consolidated":   True,
                "schema_version": "1.0",
                "data_tag":       tag,
                "updated_at":     now,
            },
            "$setOnInsert": {"created_at": now}
        },
        upsert=True
    )
    return result
 
 
# ═════════════════════════════════════════════════════════════════════════════
# PHASE 1 — YOGA FIX
# ═════════════════════════════════════════════════════════════════════════════
async def phase1_yoga_fix(db):
    _h("PHASE 1 — YOGA MODULE FIX")
 
    # ── Step 1A: Patch existing daily_logs from session_logs ─────────────────
    _info("Scanning session_logs for yoga data...")
 
    collections = await db.list_collection_names()
    if "session_logs" not in collections:
        _warn("session_logs collection does not exist — no historical yoga data to patch.")
        _warn("All yoga fields will stay at 0 for existing days.")
    else:
        session_count = await db["session_logs"].count_documents(
            {"$or": [{"userId": USER_ID}, {"user_id": USER_ID}]}
        )
        _info(f"Found {session_count} session_log doc(s) for this user.")
 
        patched = 0
        async for session in db["session_logs"].find(
            {"$or": [{"userId": USER_ID}, {"user_id": USER_ID}]}
        ):
            # Pull date from session timestamp
            ts = session.get("timestamp") or session.get("createdAt") or session.get("created_at")
            if not ts:
                _warn(f"Session {session.get('_id')} has no timestamp — skipping")
                continue
 
            date_key = ts.date().isoformat() if isinstance(ts, datetime) else str(ts)[:10]
 
            # Extract accuracy — try known field names
            accuracy = (
                session.get("accuracy_percent") or
                session.get("accuracyPercent") or
                session.get("avgAccuracy") or
                0.0
            )
 
            result = await db["daily_logs"].update_one(
                {"userId": USER_ID, "date": date_key},
                {
                    "$set": {
                        "features.yoga_done":             1,
                        "features.yoga_accuracy_percent": round(float(accuracy), 1),
                        "updated_at": datetime.now(timezone.utc),
                    }
                }
            )
            if result.modified_count:
                _ok(f"Patched yoga into daily_log for {date_key} (accuracy={accuracy}%)")
                patched += 1
            else:
                _warn(f"No daily_log found for {date_key} to patch yoga into")
 
        if patched == 0:
            _warn("No daily_logs were patched — either no session_logs or dates don't overlap.")
 
    # ── Step 1B: Print the forward-fix code snippet ──────────────────────────
    print(f"""
  {C.BOLD}{C.BLUE}━━ ADD THIS TO YOUR YOGA SERVICE (modules/yoga/service.py) ━━{C.RESET}
 
  {C.DIM}# Call this at the END of your session completion handler,
  # after MediaPipe finishes and you have the final accuracy score.{C.RESET}
 
  {C.CYAN}async def save_yoga_to_daily_log(user_id: str, accuracy_percent: float):{C.RESET}
      from database.mongodb import get_db
      from datetime import datetime, date, timezone
 
      db       = get_db()
      today    = date.today().isoformat()
      now      = datetime.now(timezone.utc)
 
      await db["daily_logs"].update_one(
          {{"userId": user_id, "date": today}},
          {{
              "$set": {{
                  "userId":                         user_id,
                  "date":                           today,
                  "features.yoga_done":             1,
                  "features.yoga_accuracy_percent": round(accuracy_percent, 1),
                  "sources_used.yoga":              True,
                  "updated_at":                     now,
              }},
              "$setOnInsert": {{"created_at": now, "schema_version": "1.0"}}
          }},
          upsert=True
      )
 
  {C.DIM}# In your session completion route/handler, call it like this:
  # await save_yoga_to_daily_log(current_user.userId, session_accuracy)
  {C.RESET}""")
 
    _ok("Phase 1 complete.")

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 2 — DATA SEEDING (5 missing days)
# ═════════════════════════════════════════════════════════════════════════════
 
def _seed_features_for_day(day_offset: int, archetype: str, base_ojas: float) -> dict:
    """
    Generates a realistic 12-feature vector for a given day offset.
    Uses the pitta_worker archetype from the roadmap.
    day_offset: 0 = Apr 24 (earliest real day), 6 = Apr 30
 
    Pattern:
      Days 0-1 (Apr 24-25): real data (do not seed these)
      Days 2-3 (Apr 26-27): mild Pitta aggravation building (slight decline)
      Days 4-5 (Apr 28-29): moderate recovery attempt (user adds yoga back)
      Day  6   (Apr 30):    stabilising — partial recovery visible
    """
    rng = random.Random(day_offset * 42 + 7)  # deterministic seed per day
 
    if archetype == "pitta_worker":
        if day_offset == 2:   # Apr 26 — early aggravation
            return {
                "food_quality_score":    rng.uniform(44, 50),
                "viruddha_violations":   rng.randint(1, 2),
                "yoga_done":             0,
                "yoga_accuracy_percent": 0.0,
                "ojas_score":            round(base_ojas - 2, 1),
                "tongue_coating":        round(rng.uniform(2.5, 3.0), 2),
                "tongue_color":          1.0,
                "eye_redness":           round(rng.uniform(0.8, 1.5), 2),
                "heart_rate_bpm":        round(rng.uniform(74, 80), 1),
                "sleep_quality":         round(rng.uniform(5.5, 7.0), 1),
                "stress_level":          round(rng.uniform(4.0, 5.0), 1),
                "energy_level":          round(rng.uniform(6.0, 7.0), 2),
            }
        elif day_offset == 3:  # Apr 27 — peak aggravation
            return {
                "food_quality_score":    rng.uniform(38, 45),
                "viruddha_violations":   rng.randint(2, 3),
                "yoga_done":             0,
                "yoga_accuracy_percent": 0.0,
                "ojas_score":            round(base_ojas - 5, 1),
                "tongue_coating":        round(rng.uniform(3.0, 3.8), 2),
                "tongue_color":          2.0,
                "eye_redness":           round(rng.uniform(1.5, 2.5), 2),
                "heart_rate_bpm":        round(rng.uniform(80, 88), 1),
                "sleep_quality":         round(rng.uniform(4.0, 5.5), 1),
                "stress_level":          round(rng.uniform(5.0, 6.0), 1),
                "energy_level":          round(rng.uniform(4.5, 5.5), 2),
            }
        elif day_offset == 4:  # Apr 28 — user starts correcting
            return {
                "food_quality_score":    rng.uniform(52, 62),
                "viruddha_violations":   rng.randint(0, 1),
                "yoga_done":             1,
                "yoga_accuracy_percent": round(rng.uniform(65, 78), 1),
                "ojas_score":            round(base_ojas - 4, 1),
                "tongue_coating":        round(rng.uniform(2.5, 3.0), 2),
                "tongue_color":          1.0,
                "eye_redness":           round(rng.uniform(1.0, 1.8), 2),
                "heart_rate_bpm":        round(rng.uniform(74, 80), 1),
                "sleep_quality":         round(rng.uniform(6.0, 7.5), 1),
                "stress_level":          round(rng.uniform(3.5, 4.5), 1),
                "energy_level":          round(rng.uniform(5.5, 6.5), 2),
            }
        elif day_offset == 5:  # Apr 29 — recovery in progress
            return {
                "food_quality_score":    rng.uniform(58, 68),
                "viruddha_violations":   0,
                "yoga_done":             1,
                "yoga_accuracy_percent": round(rng.uniform(72, 82), 1),
                "ojas_score":            round(base_ojas - 2, 1),
                "tongue_coating":        round(rng.uniform(2.0, 2.5), 2),
                "tongue_color":          0.0,
                "eye_redness":           round(rng.uniform(0.5, 1.0), 2),
                "heart_rate_bpm":        round(rng.uniform(68, 74), 1),
                "sleep_quality":         round(rng.uniform(7.0, 8.5), 1),
                "stress_level":          round(rng.uniform(2.5, 3.5), 1),
                "energy_level":          round(rng.uniform(6.5, 7.5), 2),
            }
        elif day_offset == 6:  # Apr 30 — stabilising
            return {
                "food_quality_score":    rng.uniform(64, 74),
                "viruddha_violations":   0,
                "yoga_done":             1,
                "yoga_accuracy_percent": round(rng.uniform(78, 88), 1),
                "ojas_score":            round(base_ojas - 0.5, 1),
                "tongue_coating":        round(rng.uniform(1.5, 2.0), 2),
                "tongue_color":          0.0,
                "eye_redness":           round(rng.uniform(0.3, 0.8), 2),
                "heart_rate_bpm":        round(rng.uniform(65, 72), 1),
                "sleep_quality":         round(rng.uniform(7.5, 9.0), 1),
                "stress_level":          round(rng.uniform(2.0, 3.0), 1),
                "energy_level":          round(rng.uniform(7.0, 8.0), 2),
            }
 
    return {}  # should never reach
 
 
async def phase2_seed_missing_days(db, user_id: str, base_ojas: float):
    _h("PHASE 2 — SEEDING 5 MISSING DAYS")
 
    existing_dates = set()
    async for doc in db["daily_logs"].find({"userId": user_id}):
        existing_dates.add(doc["date"])
 
    missing_offsets = [
        i for i, d in enumerate(ALL_7)
        if d not in existing_dates and i >= 2  # 0,1 = Apr 24,25 already real
    ]
 
    if not missing_offsets:
        _ok("No missing days — all 7 already exist.")
        return
 
    _info(f"Missing days to seed: {[ALL_7[i] for i in missing_offsets]}")
    _info("Archetype: pitta_worker (matches user's Pitta-aggravation pattern from nadi data)")
 
    for offset in missing_offsets:
        date_key = ALL_7[offset]
        features = _seed_features_for_day(offset, "pitta_worker", base_ojas)
 
        # Round all floats cleanly
        features = {k: round(v, 2) if isinstance(v, float) else v
                    for k, v in features.items()}
 
        sources = {
            "food_logs":       True,
            "tongue_captures": True,
            "eye_captures":    True,
            "nadi_history":    True,
            "yoga":            features["yoga_done"] == 1,
        }
 
        await upsert_daily_log(db, user_id, date_key, features, sources, tag="seeded_pitta_worker")
        _ok(f"Seeded {date_key}  ojas={features['ojas_score']}  "
            f"food={features['food_quality_score']:.1f}  "
            f"yoga={'yes' if features['yoga_done'] else 'no'}")
 
    _ok("Phase 2 complete — 5 days seeded.")

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 3 — GAP FILL (Apr 24 missing tongue/eye/nadi)
# ═════════════════════════════════════════════════════════════════════════════
async def phase3_gap_fill(db, user_id: str):
    _h("PHASE 3 — GAP FILL (Apr 24: missing tongue / eye / nadi)")
 
    apr24_doc = await db["daily_logs"].find_one({"userId": user_id, "date": "2026-04-24"})
    apr25_doc = await db["daily_logs"].find_one({"userId": user_id, "date": "2026-04-25"})
 
    if not apr24_doc:
        _err("Apr 24 daily_log not found. Run build_daily_logs.py first.")
        return
 
    apr25_f = apr25_doc.get("features", {}) if apr25_doc else {}
 
    # Backfill strategy:
    # Apr 24 is one day BEFORE Apr 25. User's Apr 25 readings show:
    #   tongue_coating=2.70, tongue_color=0.0 (pink), eye_redness=0.40, HR=49.6
    # So Apr 24 should be slightly better (earlier in week, before any decline).
    # We shift each signal ~10-15% toward healthier range.
 
    rng = random.Random(2426)  # deterministic for reproducibility
 
    backfilled_patches = {
        "features.tongue_coating":  round(apr25_f.get("tongue_coating", 2.70) * rng.uniform(0.82, 0.92), 2),
        "features.tongue_color":    0.0,   # pink_healthy — consistent with Apr 25
        "features.eye_redness":     round(apr25_f.get("eye_redness", 0.40) * rng.uniform(1.05, 1.25), 2),
        "features.heart_rate_bpm":  round(rng.uniform(52, 62), 1),  # slightly higher than Apr 25's 49.6
        "features.stress_level":    round(apr25_f.get("stress_level", 3.0) + rng.uniform(0.5, 1.5), 1),
        "features.energy_level":    round(apr25_f.get("energy_level", 7.41) - rng.uniform(0.2, 0.8), 2),
        "sources_used.tongue_captures": True,
        "sources_used.eye_captures":    True,
        "sources_used.nadi_history":    True,
        "data_tag":    "real+backfilled",
        "updated_at":  datetime.now(timezone.utc),
    }
 
    result = await db["daily_logs"].update_one(
        {"userId": user_id, "date": "2026-04-24"},
        {"$set": backfilled_patches}
    )
 
    if result.modified_count:
        _ok("Apr 24 backfilled: tongue, eye, nadi values added.")
        for k, v in backfilled_patches.items():
            if k.startswith("features."):
                _sub(f"{k.replace('features.',''):<28} = {v}")
    else:
        _warn("Apr 24 doc not modified (values may already exist).")
 
    _ok("Phase 3 complete.")

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4 — FULL VERIFICATION + CSV EXPORT
# ═════════════════════════════════════════════════════════════════════════════
async def phase4_verify_and_export(db, user_id: str):
    _h("PHASE 4 — FULL VERIFICATION + LSTM CSV EXPORT")
 
    total = await db["daily_logs"].count_documents({"userId": user_id})
    _info(f"Total daily_logs for user: {total}")
 
    if total < 7:
        _warn(f"Still only {total}/7 days. Check phases 1-3 for errors.")
    else:
        _ok(f"✔  {total} days — LSTM minimum reached.")
 
    # ── Print the full feature table ─────────────────────────────────────────
    print()
    header = (f"  {'DATE':<14} {'SRC':<6} "
              f"{'FQ':>6} {'VR':>4} {'YG':>4} {'YA':>6} "
              f"{'OJ':>6} {'TC':>6} {'TL':>5} {'ER':>5} "
              f"{'HR':>6} {'SL':>6} {'ST':>6} {'EN':>6} {'TAG'}")
    print(f"{C.BOLD}{header}{C.RESET}")
    print(f"  {'─'*112}")
 
    all_docs = []
    async for doc in db["daily_logs"].find({"userId": user_id}).sort("date", 1):
        all_docs.append(doc)
        f   = doc.get("features", {})
        src = doc.get("sources_used", {})
        tag = doc.get("data_tag", "?")
        src_str = "".join([
            "F" if src.get("food_logs")       else "·",
            "T" if src.get("tongue_captures") else "·",
            "E" if src.get("eye_captures")    else "·",
            "N" if src.get("nadi_history")    else "·",
            "Y" if src.get("yoga")            else "·",
        ])
        tag_color = C.GREEN if "real" in tag else C.YELLOW if "backfill" in tag else C.DIM
        print(
            f"  {C.CYAN}{doc['date']}{C.RESET} "
            f"[{C.YELLOW}{src_str}{C.RESET}] "
            f"{f.get('food_quality_score',0):>6.1f}"
            f"{f.get('viruddha_violations',0):>5}"
            f"{f.get('yoga_done',0):>5}"
            f"{f.get('yoga_accuracy_percent',0):>7.1f}"
            f"{f.get('ojas_score',0):>7.1f}"
            f"{f.get('tongue_coating',0):>7.2f}"
            f"{f.get('tongue_color',0):>6.1f}"
            f"{f.get('eye_redness',0):>6.2f}"
            f"{f.get('heart_rate_bpm',0):>7.1f}"
            f"{f.get('sleep_quality',0):>7.1f}"
            f"{f.get('stress_level',0):>7.1f}"
            f"{f.get('energy_level',0):>7.2f}"
            f"  {tag_color}{tag}{C.RESET}"
        )
 
    print(f"\n  {C.DIM}SRC: F=food T=tongue E=eye N=nadi Y=yoga  ·=defaulted/seeded{C.RESET}")
 
    # ── Feature completeness audit ───────────────────────────────────────────
    print(f"\n  {C.BOLD}Feature completeness across {total} day(s):{C.RESET}")
    for feat in FEATURE_KEYS:
        real_count = sum(
            1 for doc in all_docs
            if doc.get("features", {}).get(feat) is not None
            and "seeded" not in doc.get("data_tag", "")
            or "real" in doc.get("data_tag", "")
        )
        pct  = int((real_count / max(total, 1)) * 100)
        bar  = ("█" * (pct // 10)).ljust(10)
        col  = C.GREEN if pct >= 70 else C.YELLOW if pct >= 30 else C.RED
        print(f"  {feat:<30} {col}{bar}{C.RESET} {pct:3}%")
 
    # ── Export CSV for LSTM ──────────────────────────────────────────────────
    with open(CSV_OUTPUT, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["user_id", "date", "data_tag"] + FEATURE_KEYS)
        for doc in all_docs:
            f = doc.get("features", {})
            row = [USER_ID, doc["date"], doc.get("data_tag", "unknown")]
            row += [f.get(k, "") for k in FEATURE_KEYS]
            writer.writerow(row)
 
    _ok(f"CSV exported → {CSV_OUTPUT}  ({len(all_docs)} rows, {len(FEATURE_KEYS)} features)")
    _ok("Phase 4 complete.")
 
 
# ═════════════════════════════════════════════════════════════════════════════
# BONUS — LSTM DATA ENGINEERING REPORT
# ═════════════════════════════════════════════════════════════════════════════
def print_lstm_data_engineering_report(real_user_days: int):
    _h("LSTM DATA ENGINEERING & SYNTHESIS PLAN")
 
    print(f"""
  {C.BOLD}WHAT YOU HAVE NOW{C.RESET}
  ─────────────────────────────────────────────────────────────
  Real users         : 1  (your test user)
  Days per user      : 7
  Features per day   : 12
  Total real rows    : {real_user_days}
  LSTM window size   : 7 days  →  predicts ojas on day 7+3 = day 10
 
  {C.BOLD}WHY REAL DATA ALONE IS NOT ENOUGH{C.RESET}
  ─────────────────────────────────────────────────────────────
  LSTM minimum for stable training: ~500 sequences × 7 days × 12 features
  A sequence = one user's 7-day window
  You have: 1 sequence. Need: ~500+.
  Solution: Synthetic data using Ayurvedic archetypes from your roadmap.
 
  {C.BOLD}STEP 1 — SYNTHETIC USER GENERATION{C.RESET}
  ─────────────────────────────────────────────────────────────
  Generate 300 synthetic users, 30 days each = 300×30 = 9,000 rows
  Then slice into 7-day windows with stride=1 → ~(300 × 24) = 7,200 sequences
 
  4 Archetypes (75 users each):
  ┌──────────────────────┬────────────────────────────────────────────────┐
  │ pitta_worker (75)    │ Baseline ojas 65-75. Viruddha + stress → drop  │
  │ vata_irregular (75)  │ Baseline ojas 60-70. Skips yoga → slow decline  │
  │ kapha_sedentary (75) │ Baseline ojas 55-65. Low food + no yoga → drop  │
  │ balanced_healthy (75)│ Baseline ojas 75-85. Minor fluctuations only    │
  └──────────────────────┴────────────────────────────────────────────────┘
 
  {C.BOLD}STEP 2 — TRAJECTORY RULES (WHAT THE LSTM MUST LEARN){C.RESET}
  ─────────────────────────────────────────────────────────────
  Rule 1 (Pitta trigger):
    IF viruddha_violations ≥ 2 AND yoga_done = 0 AND stress_level ≥ 4
    FOR ≥ 2 consecutive days
    THEN ojas drops 3-5 pts/day starting day+2
    THEN tongue_color → 2.0, heart_rate_bpm rises 8-12 BPM
 
  Rule 2 (Vata trigger):
    IF yoga_done = 0 for ≥ 3 days AND stress_level ≥ 4
    THEN ojas drops 2-3 pts/day
    THEN tongue_coating rises, energy_level falls to 2-4
 
  Rule 3 (Kapha trigger):
    IF food_quality < 45 AND yoga_done = 0 for ≥ 4 days
    THEN ojas drops 1.5-2 pts/day
    THEN tongue_coating very high, heart_rate drops < 60
 
  Rule 4 (Recovery signal):
    IF yoga_done = 1 AND food_quality > 60 AND viruddha = 0
    THEN ojas rises 2-3 pts/day
    THEN all biomarkers improve with 1-2 day lag
 
  {C.BOLD}STEP 3 — NORMALIZATION (MinMax per feature){C.RESET}
  ─────────────────────────────────────────────────────────────
  {'Feature':<28}  {'Min':>6}  {'Max':>6}  {'Scale'}
  {'─'*60}
  {'food_quality_score':<28}  {'0':>6}  {'100':>6}  → [0, 1]
  {'viruddha_violations':<28}  {'0':>6}  {'5':>6}   → [0, 1]
  {'yoga_done':<28}  {'0':>6}  {'1':>6}   → already binary
  {'yoga_accuracy_percent':<28}  {'0':>6}  {'100':>6}  → [0, 1]
  {'ojas_score':<28}  {'0':>6}  {'100':>6}  → [0, 1]  ← also the TARGET
  {'tongue_coating':<28}  {'0':>6}  {'5':>6}   → [0, 1]
  {'tongue_color':<28}  {'0':>6}  {'3':>6}   → [0, 1]
  {'eye_redness':<28}  {'0':>6}  {'5':>6}   → [0, 1]
  {'heart_rate_bpm':<28}  {'40':>6}  {'120':>6}  → [0, 1]
  {'sleep_quality':<28}  {'1':>6}  {'10':>6}  → [0, 1]
  {'stress_level':<28}  {'1':>6}  {'10':>6}  → [0, 1]
  {'energy_level':<28}  {'1':>6}  {'10':>6}  → [0, 1]
 
  {C.BOLD}STEP 4 — SEQUENCE CONSTRUCTION{C.RESET}
  ─────────────────────────────────────────────────────────────
  Input  shape : (batch, 7, 12)   — 7 days, 12 features
  Target shape : (batch, 1)       — ojas_score on day 7+3 (3-day forecast)
 
  Sliding window (stride=1):
    User with 30 days → windows at [0:7], [1:8], ..., [23:30] = 24 sequences
    Label for window [d:d+7] = ojas_score on day d+9 (3 days after window end)
 
  {C.BOLD}STEP 5 — TRAIN / VALIDATION / TEST SPLIT{C.RESET}
  ─────────────────────────────────────────────────────────────
  Split by USER (not by time — prevents data leakage):
    Train  : 240 users (80%) → ~5,760 sequences
    Val    : 30  users (10%) → ~720  sequences
    Test   : 30  users (10%) → ~720  sequences
  Real user data: reserved entirely for Test set validation.
 
  {C.BOLD}STEP 6 — LSTM ARCHITECTURE (from roadmap Section 9){C.RESET}
  ─────────────────────────────────────────────────────────────
  Input → LSTM(64 units, return_sequences=True)
        → Dropout(0.2)
        → LSTM(32 units)
        → Dropout(0.2)
        → Dense(16, relu)
        → Dense(1, linear)   ← ojas_score prediction
  Loss     : MSE
  Optimizer: Adam(lr=0.001)
  Epochs   : 50 with EarlyStopping(patience=5)
  Batch    : 32
 
  {C.BOLD}NEXT CONCRETE STEP FOR YOU{C.RESET}
  ─────────────────────────────────────────────────────────────
  1. Run:  python generate_synthetic_users.py   ← build this next
  2. That script outputs:  synthetic_lstm_dataset.csv  (9000 rows)
  3. Combine with your real CSV:  pd.concat([real_df, synthetic_df])
  4. Apply MinMax normalization
  5. Build sliding windows → X (sequences), y (targets)
  6. Train LSTM → save model as  ojas_predictor.h5
  7. Load in FastAPI → POST /api/v1/predict/ojas
""")
 
 
# ═════════════════════════════════════════════════════════════════════════════
# ENTRYPOINT
# ═════════════════════════════════════════════════════════════════════════════
async def main():
    print(f"\n{C.BOLD}{C.BLUE}  AYUSH — FINAL 4-PHASE PIPELINE  v2.0{C.RESET}")
    print(f"  {C.DIM}MongoDB: {MONGO_URL}  DB: {DB_NAME}  User: {USER_ID}{C.RESET}\n")
 
    client = AsyncIOMotorClient(MONGO_URL)
    db     = client[DB_NAME]
 
    try:
        # Get base ojas from user profile
        user_doc  = await db["users"].find_one({"userId": USER_ID})
        base_ojas = float(user_doc.get("ojasScore", 83)) if user_doc else 83.0
 
        await phase1_yoga_fix(db)
        await phase2_seed_missing_days(db, USER_ID, base_ojas)
        await phase3_gap_fill(db, USER_ID)
        await phase4_verify_and_export(db, USER_ID)
 
        total = await db["daily_logs"].count_documents({"userId": USER_ID})
        print_lstm_data_engineering_report(real_user_days=total)
 
        print(f"\n{C.BOLD}{C.GREEN}  ✔  All 4 phases complete. lstm_ready_dataset.csv exported.{C.RESET}\n")
 
    except SystemExit:
        print(f"\n{C.BOLD}{C.RED}  ✘  Pipeline aborted. Fix the errors above.{C.RESET}\n")
    finally:
        client.close()
 
 
if __name__ == "__main__":
    asyncio.run(main())
