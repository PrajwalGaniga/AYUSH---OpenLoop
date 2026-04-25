import cv2
import numpy as np

def analyze_eye(image_bytes: bytes) -> dict:
    """
    Eye sclera analysis.
    Detects redness index and jaundice flag.
    """
    
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        return {"error": "Invalid image"}
    
    # STEP 1: Isolate sclera (white of the eye)
    # Convert to HSV
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # Sclera: low saturation, high value (white region)
    lower_sclera = np.array([0, 0, 150])
    upper_sclera = np.array([180, 50, 255])
    sclera_mask = cv2.inRange(hsv, lower_sclera, upper_sclera)
    
    # Clean mask
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    sclera_mask = cv2.morphologyEx(sclera_mask, cv2.MORPH_OPEN, kernel)
    
    sclera_pixels_count = int(np.sum(sclera_mask > 0))
    
    if sclera_pixels_count < 100:
        return {"error": "Sclera not detected clearly. Retake."}
    
    # STEP 2: Redness Analysis (LAB colorspace)
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    
    # A-channel in LAB: positive = red, negative = green
    a_channel = lab[:, :, 1].astype(float)
    sclera_a_values = a_channel[sclera_mask > 0]
    mean_a = float(np.mean(sclera_a_values))
    
    # Redness index: normalized A-channel mean
    # Healthy sclera: mean_a ≈ 128 (neutral in uint8 space, ~0 in signed)
    # Redness: mean_a > 135 (signed: > 7)
    redness_index = int(np.clip((mean_a - 125) / 30 * 100, 0, 100))
    
    # STEP 3: Jaundice Detection (B-channel in LAB)
    # B-channel: positive = yellow, negative = blue
    b_channel = lab[:, :, 2].astype(float)
    sclera_b_values = b_channel[sclera_mask > 0]
    mean_b = float(np.mean(sclera_b_values))
    
    # Jaundice: high B value (yellowing)
    # Healthy: mean_b ≈ 128 (neutral)
    # Jaundice flag threshold: mean_b > 140
    jaundice_score = int(np.clip((mean_b - 128) / 30 * 100, 0, 100))
    jaundice_flag = jaundice_score > 40  # flag if clearly yellow
    
    # STEP 4: Eye health composite score (0-100)
    # Lower redness and no jaundice = higher score
    eye_health_score = int(max(0, 100 - (redness_index * 0.7) - (jaundice_score * 0.3)))
    
    # STEP 5: Redness classification
    if redness_index < 20:
        redness_class = "clear"
    elif redness_index < 45:
        redness_class = "mild_redness"
    elif redness_index < 70:
        redness_class = "moderate_redness"
    else:
        redness_class = "severe_redness"
    
    return {
        "redness_index": redness_index,             # 0-100, used for LSTM
        "redness_classification": redness_class,
        "jaundice_score": jaundice_score,
        "jaundice_flag": jaundice_flag,
        "eye_health_score": eye_health_score,       # Composite, used for LSTM
        "sclera_coverage": sclera_pixels_count,
        "dosha_signal": _get_eye_dosha_signal(redness_class, jaundice_flag),
    }


def _get_eye_dosha_signal(redness: str, jaundice: bool) -> str:
    messages = {
        "clear": "Eyes are clear. Liver and Pitta are balanced.",
        "mild_redness": "Mild Pitta aggravation — reduce screen time, apply rose water.",
        "moderate_redness": "Elevated Pitta — avoid spicy food, get 8 hours sleep.",
        "severe_redness": "Significant Pitta/Vata imbalance — consult an Ayurvedic practitioner.",
    }
    msg = messages.get(redness, "")
    if jaundice:
        msg += " Yellowing detected — liver health monitoring recommended. See a doctor."
    return msg
