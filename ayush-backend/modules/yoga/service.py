import json
import base64
import math
import numpy as np
import cv2
import mediapipe as mp
from pathlib import Path
from modules.yoga.schemas import PoseCheckRequest, PoseCheckResponse, JointFeedback

# Load reference poses once at startup
REFERENCE_POSES_PATH = Path("yolo-model/asana_reference_poses.json")
reference_data = json.loads(REFERENCE_POSES_PATH.read_text(encoding="utf-8"))
ASANA_DB = reference_data["asanas"]
TOLERANCE = reference_data["metadata"]["angle_tolerance_degrees"]

# Initialize MediaPipe once at startup
mp_pose = mp.solutions.pose
pose_detector = mp_pose.Pose(
    static_image_mode=True,
    model_complexity=1,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

def calculate_angle(a, b, c) -> float:
    """
    Calculate angle at point b given three points a, b, c.
    Each point is a tuple (x, y).
    Returns angle in degrees.
    """
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    
    ba = a - b
    bc = c - b
    
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-8)
    cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
    angle = np.degrees(np.arccos(cosine_angle))
    return round(angle, 2)

def extract_landmark(landmarks, index: int, width: int, height: int) -> tuple:
    lm = landmarks[index]
    return (lm.x * width, lm.y * height)

def check_pose(request: PoseCheckRequest) -> PoseCheckResponse:
    asana_id = request.asana_id
    
    if asana_id not in ASANA_DB:
        return PoseCheckResponse(
            asana_id=asana_id,
            overall_correct=False,
            accuracy_percent=0.0,
            joint_feedbacks=[],
            primary_correction="Unknown pose selected",
            landmarks_visible=False,
            visibility_message="Unknown asana ID",
            landmarks=[]
        )
    
    asana = ASANA_DB[asana_id]
    reference_angles = asana.get("reference_angles", {})
    corrections_db = asana.get("corrections", {})
    
    # Decode base64 frame
    try:
        # Handle base64 prefix if exists
        b64_data = request.frame_base64
        if ',' in b64_data:
            b64_data = b64_data.split(',')[1]
        img_bytes = base64.b64decode(b64_data)
        np_arr = np.frombuffer(img_bytes, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if frame is None:
            raise ValueError("Could not decode image")
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    except Exception as e:
        return PoseCheckResponse(
            asana_id=asana_id,
            overall_correct=False,
            accuracy_percent=0.0,
            joint_feedbacks=[],
            primary_correction="Error processing image frame.",
            landmarks_visible=False,
            visibility_message="Image processing error",
            landmarks=[]
        )
    
    h, w = frame.shape[:2]
    
    # Run MediaPipe
    results = pose_detector.process(frame_rgb)
    
    if not results.pose_landmarks:
        return PoseCheckResponse(
            asana_id=asana_id,
            overall_correct=False,
            accuracy_percent=0.0,
            joint_feedbacks=[],
            primary_correction="Cannot see your body clearly. Please step back and ensure good lighting.",
            landmarks_visible=False,
            visibility_message="No pose detected. Step back so your full body is visible.",
            landmarks=[]
        )
    
    lm = results.pose_landmarks.landmark
    
    landmark_list = [
        {"x": round(lm[i].x, 4), "y": round(lm[i].y, 4), "visibility": round(lm[i].visibility, 3)}
        for i in range(33)
    ]
    
    # Check visibility of key landmarks
    key_indices = [11, 12, 23, 24, 25, 26, 27, 28]
    visibility_scores = [lm[i].visibility for i in key_indices]
    if min(visibility_scores) < 0.3:
        return PoseCheckResponse(
            asana_id=asana_id,
            overall_correct=False,
            accuracy_percent=0.0,
            joint_feedbacks=[],
            primary_correction="Part of your body is out of frame. Step back so your full body is visible.",
            landmarks_visible=False,
            visibility_message="Key landmarks not visible. Ensure full body is in frame.",
            landmarks=landmark_list
        )
    
    # Extract key points
    L_SHOULDER = extract_landmark(lm, 11, w, h)
    R_SHOULDER = extract_landmark(lm, 12, w, h)
    L_ELBOW    = extract_landmark(lm, 13, w, h)
    R_ELBOW    = extract_landmark(lm, 14, w, h)
    L_WRIST    = extract_landmark(lm, 15, w, h)
    R_WRIST    = extract_landmark(lm, 16, w, h)
    L_HIP      = extract_landmark(lm, 23, w, h)
    R_HIP      = extract_landmark(lm, 24, w, h)
    L_KNEE     = extract_landmark(lm, 25, w, h)
    R_KNEE     = extract_landmark(lm, 26, w, h)
    L_ANKLE    = extract_landmark(lm, 27, w, h)
    R_ANKLE    = extract_landmark(lm, 28, w, h)
    NOSE       = extract_landmark(lm, 0, w, h)
    
    # Mid points
    MID_SHOULDER = ((L_SHOULDER[0]+R_SHOULDER[0])/2, (L_SHOULDER[1]+R_SHOULDER[1])/2)
    MID_HIP      = ((L_HIP[0]+R_HIP[0])/2, (L_HIP[1]+R_HIP[1])/2)
    VERTICAL_REF = (MID_HIP[0], MID_HIP[1] - 100)  # point directly above hip
    
    # Calculate all detectable angles
    detected_angles = {
        "spine_vertical_angle":   calculate_angle(NOSE, MID_SHOULDER, MID_HIP),
        "left_hip_angle":         calculate_angle(L_SHOULDER, L_HIP, L_KNEE),
        "right_hip_angle":        calculate_angle(R_SHOULDER, R_HIP, R_KNEE),
        "left_knee_angle":        calculate_angle(L_HIP, L_KNEE, L_ANKLE),
        "right_knee_angle":       calculate_angle(R_HIP, R_KNEE, R_ANKLE),
        "left_elbow_angle":       calculate_angle(L_SHOULDER, L_ELBOW, L_WRIST),
        "right_elbow_angle":      calculate_angle(R_SHOULDER, R_ELBOW, R_WRIST),
        "left_shoulder_angle":    calculate_angle(L_ELBOW, L_SHOULDER, L_HIP),
        "right_shoulder_angle":   calculate_angle(R_ELBOW, R_SHOULDER, R_HIP),
        "hip_angle":              calculate_angle(MID_SHOULDER, MID_HIP, L_KNEE),
        "spine_angle":            calculate_angle(NOSE, MID_SHOULDER, MID_HIP),
        "spine_extension_angle":  calculate_angle(MID_HIP, MID_SHOULDER, NOSE),
    }
    
    # Compare with reference
    joint_feedbacks = []
    incorrect_feedbacks = []
    
    for angle_key, ref_angle in reference_angles.items():
        if angle_key not in detected_angles:
            continue
        
        detected = detected_angles[angle_key]
        deviation = abs(detected - ref_angle)
        is_correct = deviation <= TOLERANCE
        
        correction_msg = ""
        if not is_correct and angle_key in corrections_db:
            if detected < ref_angle:
                correction_msg = corrections_db[angle_key].get("too_low", "")
            else:
                correction_msg = corrections_db[angle_key].get("too_high", "")
        
        fb = JointFeedback(
            joint_name=angle_key,
            reference_angle=ref_angle,
            detected_angle=detected,
            deviation=round(deviation, 2),
            is_correct=is_correct,
            correction_message=correction_msg
        )
        joint_feedbacks.append(fb)
        if not is_correct and correction_msg:
            incorrect_feedbacks.append((deviation, correction_msg))
    
    # Accuracy: percentage of joints within tolerance
    if joint_feedbacks:
        correct_count = sum(1 for f in joint_feedbacks if f.is_correct)
        accuracy = round((correct_count / len(joint_feedbacks)) * 100, 1)
    else:
        accuracy = 100.0  # e.g. shavasana with no angles checked
    
    overall_correct = accuracy >= 70.0
    
    # Primary correction: the joint with the LARGEST deviation
    incorrect_feedbacks.sort(key=lambda x: x[0], reverse=True)
    primary_correction = incorrect_feedbacks[0][1] if incorrect_feedbacks else "Great posture! Hold steady."
    
    return PoseCheckResponse(
        asana_id=asana_id,
        overall_correct=overall_correct,
        accuracy_percent=accuracy,
        joint_feedbacks=joint_feedbacks,
        primary_correction=primary_correction,
        landmarks_visible=True,
        visibility_message="Full body detected",
        landmarks=landmark_list
    )
