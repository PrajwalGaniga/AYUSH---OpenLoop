import numpy as np
import tensorflow as tf
from PIL import Image
import sys
import os

# --- Configuration ---
MODEL_PATH = 'plant_classifier_int8.tflite'
LABELS_PATH = 'plant_labels.txt'

def load_labels(filename):
    if not os.path.exists(filename):
        print(f"❌ Error: Cannot find {filename}. Make sure it is in the same folder.")
        sys.exit(1)
    with open(filename, 'r') as f:
        return [line.strip() for line in f.readlines()]

def predict_image(image_path):
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Error: Cannot find {MODEL_PATH}. Make sure it is in the same folder.")
        sys.exit(1)

    print(f"🌿 Loading TFLite Brain...")
    
    # 1. Load the labels and model
    labels = load_labels(LABELS_PATH)
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"Input details: {input_details[0]['shape']}, {input_details[0]['dtype']}, {input_details[0]['quantization']}")
    print(f"Output details: {output_details[0]['shape']}, {output_details[0]['dtype']}, {output_details[0]['quantization']}")

    # 2. Load and preprocess the image (Squash to 380x380)
    try:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((380, 380))
    except Exception as e:
        print(f"❌ Error loading image: {e}")
        sys.exit(1)

    # Convert to mathematical array and add batch dimension
    img_array = np.array(img)
    img_array = np.expand_dims(img_array, axis=0) 

    if input_details[0]['dtype'] == np.uint8:
        img_array = img_array.astype(np.uint8)
    else:
        img_array = img_array.astype(np.float32)

    # 3. Run the model
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()

    # 4. Extract raw bytes
    predictions = interpreter.get_tensor(output_details[0]['index'])[0]

    # 🛠️ THE DE-QUANTIZATION FIX 🛠️
    if output_details[0]['dtype'] != np.float32:
        scale, zero_point = output_details[0]['quantization']
        predictions = (predictions.astype(np.float32) - zero_point) * scale

    # Apply softmax just to be sure we see proper percentages if model didn't include it
    exp_scores = np.exp(predictions - np.max(predictions))
    softmax = exp_scores / exp_scores.sum()

    # 5. Display Top 3 Results
    top_3_indices = np.argsort(softmax)[-3:][::-1]

    print(f"\n📊 --- RESULTS FOR: {image_path} ---")
    for i in top_3_indices:
        confidence = softmax[i] * 100
        marker = "✅" if confidence >= 70 else "⚠️"
        print(f"{marker} {labels[i]:<15} : {confidence:.2f}% (raw: {predictions[i]:.4f})")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("💡 Usage: python script.py <image_filename.jpg>")
    else:
        predict_image(sys.argv[1])
