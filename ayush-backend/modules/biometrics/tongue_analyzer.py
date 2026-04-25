import cv2
import numpy as np

def analyze_tongue(image_bytes: bytes) -> dict:
    """
    OpenCV-based tongue analysis.
    Returns coating score and color score.
    """
    
    # Decode image
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        return {"error": "Invalid image"}
    
    # STEP 1: Isolate tongue region
    # Convert to HSV for skin/tongue color masking
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # Tongue color range in HSV (reddish-pink range)
    lower_tongue = np.array([0, 50, 80])
    upper_tongue = np.array([20, 255, 255])
    tongue_mask = cv2.inRange(hsv, lower_tongue, upper_tongue)
    
    # Clean mask: morphological operations
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    tongue_mask = cv2.morphologyEx(tongue_mask, cv2.MORPH_CLOSE, kernel)
    tongue_mask = cv2.morphologyEx(tongue_mask, cv2.MORPH_OPEN, kernel)
    
    # Apply mask
    tongue_region = cv2.bitwise_and(img, img, mask=tongue_mask)
    
    # STEP 2: Coating Detection (white/yellow coating = Ama)
    # Convert to LAB for better perceptual analysis
    lab = cv2.cvtColor(tongue_region, cv2.COLOR_BGR2LAB)
    l_channel = lab[:, :, 0]
    
    # High L value + low saturation in HSV = white coating
    # Extract only tongue pixels
    tongue_pixels = l_channel[tongue_mask > 0]
    
    if len(tongue_pixels) == 0:
        return {"error": "Tongue not detected. Retake in better lighting."}
    
    mean_brightness = float(np.mean(tongue_pixels))
    
    # Coating score: higher brightness = more coating = more Ama
    # Normalize: 0 = no coating, 100 = heavy white coating
    # Healthy tongue brightness in LAB L channel: ~100-130
    # Heavy coating: > 160
    coating_score = int(np.clip((mean_brightness - 100) / 80 * 100, 0, 100))
    
    # STEP 3: Color Analysis
    # Extract dominant hue from tongue region
    tongue_hsv = hsv.copy()
    tongue_hsv[tongue_mask == 0] = 0
    tongue_hue = tongue_hsv[:, :, 0][tongue_mask > 0]
    mean_hue = float(np.mean(tongue_hue))
    saturation_vals = tongue_hsv[:, :, 1][tongue_mask > 0]
    mean_saturation = float(np.mean(saturation_vals))
    
    # Classify color
    if mean_hue < 5 or mean_hue > 170:
        color_classification = "pale_white"    # Vata/Kapha imbalance
    elif 0 <= mean_hue <= 15 and mean_saturation > 150:
        color_classification = "red"           # Pitta imbalance/heat
    elif 15 < mean_hue <= 30:
        color_classification = "pink_healthy"  # Balanced
    elif mean_hue > 30:
        color_classification = "yellow"        # Pitta + Ama
    else:
        color_classification = "unknown"
    
    # Color score: 0 = very pale/very red (imbalanced), 100 = healthy pink
    color_score_map = {
        "pink_healthy": 90,
        "pale_white": 40,
        "red": 25,
        "yellow": 35,
        "unknown": 50,
    }
    color_score = color_score_map[color_classification]
    
    # STEP 4: Composite Tongue Health Score (0-100, higher = healthier)
    tongue_health_score = int((100 - coating_score) * 0.6 + color_score * 0.4)
    
    return {
        "coating_score": coating_score,          # 0=clean, 100=heavily coated
        "color_classification": color_classification,
        "color_score": color_score,              # 0-100 health proxy
        "tongue_health_score": tongue_health_score,  # Composite, used for LSTM
        "dosha_signal": _get_dosha_signal(color_classification, coating_score),
        "ama_level": _classify_ama(coating_score),   # "none" | "mild" | "moderate" | "heavy"
    }


def _classify_ama(coating_score: int) -> str:
    if coating_score < 20: return "none"
    elif coating_score < 45: return "mild"
    elif coating_score < 70: return "moderate"
    else: return "heavy"

def _get_dosha_signal(color: str, coating: int) -> str:
    signals = {
        "red": "Pitta aggravated — cooling foods recommended",
        "pale_white": "Vata/Kapha dominance — warming, light foods recommended",
        "yellow": "Pitta + Ama accumulation — detox protocol recommended",
        "pink_healthy": "Balanced — maintain current routine",
    }
    base = signals.get(color, "Inconclusive — retake in better lighting")
    if coating > 50:
        base += ". Heavy Ama present — consider 1-day light diet."
    return base
