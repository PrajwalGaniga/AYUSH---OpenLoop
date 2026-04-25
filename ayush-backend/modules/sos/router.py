import traceback
from fastapi import APIRouter, HTTPException
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from config.settings import settings
from .schemas import SOSTriggerRequest, SOSTriggerResponse
from datetime import datetime

router = APIRouter(prefix="/api/v1/sos", tags=["sos"])

_twilio_client: Client | None = None

def get_twilio_client() -> Client:
    global _twilio_client
    if _twilio_client is None:
        sid = settings.twilio_account_sid
        token = settings.twilio_auth_token
        print(f"\n[SOS] Initializing Twilio client...")
        print(f"[SOS] Account SID: {sid[:8]}..." if sid else "[SOS] ❌ SID MISSING")
        print(f"[SOS] Auth Token: {'SET' if token else '❌ MISSING'}")
        print(f"[SOS] From Number: {settings.twilio_from_number}")
        if not sid or not token:
            raise RuntimeError("TWILIO_ACCOUNT_SID or TWILIO_AUTH_TOKEN not configured in .env")
        _twilio_client = Client(sid, token)
        print(f"[SOS] ✅ Twilio client ready")
    return _twilio_client


@router.post("/trigger", response_model=SOSTriggerResponse)
async def trigger_sos(request: SOSTriggerRequest):
    print(f"\n{'='*60}")
    print(f"[SOS] 🚨 TRIGGER RECEIVED")
    print(f"[SOS]   User      : {request.user_name}")
    print(f"[SOS]   Guardian  : {request.guardian_phone}")
    print(f"[SOS]   Timestamp : {datetime.now().strftime('%d %b %Y %H:%M:%S')}")
    print(f"{'='*60}")

    # Normalise guardian number → E.164
    guardian = request.guardian_phone.strip()
    if not guardian.startswith("+"):
        guardian = "+91" + guardian.lstrip("0")
    print(f"[SOS]   Normalised guardian: {guardian}")

    if len(guardian) < 10:
        print(f"[SOS] ❌ Guardian number too short — aborting")
        raise HTTPException(status_code=400, detail="Invalid guardian phone number")

    timestamp = datetime.now().strftime("%d %b %Y at %I:%M %p IST")
    location_text = ""
    if request.latitude and request.longitude:
        location_text = f"\nLocation: https://maps.google.com/?q={request.latitude},{request.longitude}"

    sms_body = (
        f"🚨 EMERGENCY — FALL DETECTED\n"
        f"AYUSH app detected that {request.user_name} may have fallen.\n"
        f"Time: {timestamp}{location_text}\n"
        f"Please call them immediately or go to their location."
    )

    call_sid = None
    sms_sid = None
    errors = []

    try:
        client = get_twilio_client()
        from_number = settings.twilio_from_number
    except RuntimeError as e:
        print(f"[SOS] ❌ Twilio init failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

    # ── 1. Voice Call ────────────────────────────────────────────────────────
    print(f"\n[SOS] 📞 Placing voice call: {from_number} → {guardian}")
    try:
        twiml = (
            f'<Response>'
            f'<Say voice="alice" language="en-IN">'
            f'This is an emergency alert from AYUSH app. '
            f'{request.user_name} may have fallen and needs help. '
            f'Please call them immediately. This message will repeat.'
            f'</Say>'
            f'<Pause length="1"/>'
            f'<Say voice="alice" language="en-IN">'
            f'{request.user_name} may have fallen and needs help. Please call them now.'
            f'</Say>'
            f'</Response>'
        )
        call = client.calls.create(
            to=guardian,
            from_=from_number,
            twiml=twiml,
            timeout=30,
        )
        call_sid = call.sid
        print(f"[SOS] ✅ Call placed — SID={call_sid} | Status={call.status}")
    except TwilioRestException as e:
        print(f"[SOS] ❌ CALL FAILED")
        print(f"[SOS]   Code   : {e.code}")
        print(f"[SOS]   Message: {e.msg}")
        print(f"[SOS]   Details: {e.details}")
        errors.append(f"Call: {e.msg}")
    except Exception as e:
        print(f"[SOS] ❌ UNEXPECTED CALL ERROR: {e}")
        traceback.print_exc()
        errors.append(f"Call unexpected: {str(e)}")

    # ── 2. SMS ───────────────────────────────────────────────────────────────
    print(f"\n[SOS] 💬 Sending SMS to {guardian}")
    try:
        msg = client.messages.create(
            to=guardian,
            from_=from_number,
            body=sms_body,
        )
        sms_sid = msg.sid
        print(f"[SOS] ✅ SMS sent — SID={sms_sid} | Status={msg.status}")
    except TwilioRestException as e:
        print(f"[SOS] ❌ SMS FAILED")
        print(f"[SOS]   Code   : {e.code}")
        print(f"[SOS]   Message: {e.msg}")
        print(f"[SOS]   Details: {e.details}")
        errors.append(f"SMS: {e.msg}")
    except Exception as e:
        print(f"[SOS] ❌ UNEXPECTED SMS ERROR: {e}")
        traceback.print_exc()
        errors.append(f"SMS unexpected: {str(e)}")

    print(f"\n[SOS] Summary: call_sid={call_sid} | sms_sid={sms_sid} | errors={errors}")
    print(f"{'='*60}\n")

    if not call_sid and not sms_sid:
        raise HTTPException(
            status_code=500,
            detail=f"Both call and SMS failed: {'; '.join(errors)}"
        )

    return SOSTriggerResponse(
        success=True,
        call_sid=call_sid,
        sms_sid=sms_sid,
        message=f"Emergency alert sent to {guardian}. {'Errors: ' + ', '.join(errors) if errors else 'All alerts successful.'}",
    )


@router.get("/health")
async def sos_health():
    sid = settings.twilio_account_sid
    token = settings.twilio_auth_token
    print(f"[SOS] Health check — SID={'SET' if sid else 'MISSING'} | Token={'SET' if token else 'MISSING'} | From={settings.twilio_from_number}")
    return {
        "configured": bool(sid and token),
        "from_number": settings.twilio_from_number,
        "sid_prefix": sid[:8] + "..." if sid else "MISSING",
        "token_set": bool(token),
    }
