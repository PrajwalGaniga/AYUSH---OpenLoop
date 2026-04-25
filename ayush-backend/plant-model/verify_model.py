"""
AYUSH Module 6 — Model Verification Script
Run: python verify_model.py
Confirms: input shape, dtype, output shape, label count, top-3 prediction on test image
"""
import numpy as np
import tensorflow as tf
from PIL import Image
import json, os, sys

MODEL_PATH  = r"C:\Users\ASUS\Desktop\OpenLoop\ayush-backend\plant-model\plant_classifier_int8.tflite"
META_PATH   = r"C:\Users\ASUS\Desktop\OpenLoop\ayush-backend\plant-model\plant_matadata.json"
TEST_IMAGE  = r"C:\Users\ASUS\Desktop\OpenLoop\ayush-backend\plant-model\test-img\image.png"

print("=" * 60)
print("  AYUSH — Plant Classifier Model Verification")
print("=" * 60)

# ── 1. Load labels from metadata ──────────────────────────────────────────────
with open(META_PATH, encoding="utf-8") as f:
    meta = json.load(f)
labels = meta["metadata"]["tflite_class_order"]
print(f"\n✅ Labels loaded from metadata: {len(labels)} classes")
for i, lbl in enumerate(labels):
    print(f"   [{i:2d}] {lbl}")

# ── 2. Load TFLite model & inspect tensors ────────────────────────────────────
interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()

input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

inp = input_details[0]
out = output_details[0]

print(f"\n📐 INPUT  TENSOR:")
print(f"   shape : {inp['shape']}")
print(f"   dtype : {inp['dtype']}")
print(f"   quant : scale={inp['quantization'][0]:.6f}, zero_point={inp['quantization'][1]}")

print(f"\n📐 OUTPUT TENSOR:")
print(f"   shape : {out['shape']}")
print(f"   dtype : {out['dtype']}")
print(f"   quant : scale={out['quantization'][0]:.6f}, zero_point={out['quantization'][1]}")

input_h = int(inp['shape'][1])
input_w = int(inp['shape'][2])
print(f"\n📏 Confirmed input size: {input_h} x {input_w}")

num_classes = int(out['shape'][1])
print(f"📊 Output classes: {num_classes}")

if num_classes != len(labels):
    print(f"\n🚨 CRITICAL MISMATCH: model outputs {num_classes} classes but metadata has {len(labels)} labels!")
    sys.exit(1)
else:
    print(f"✅ Class count matches: {num_classes} == {len(labels)}")

# ── 3. Run inference on test image ────────────────────────────────────────────
print(f"\n🔍 Running inference on: {TEST_IMAGE}")
img = Image.open(TEST_IMAGE).convert("RGB")
img_resized = img.resize((input_w, input_h))
img_array = np.array(img_resized)
img_array = np.expand_dims(img_array, axis=0)

# Match input dtype exactly
if inp['dtype'] == np.uint8:
    img_array = img_array.astype(np.uint8)
    print("   Input dtype: uint8 (raw pixels, no normalization)")
elif inp['dtype'] == np.int8:
    # Quantized int8: (pixel / 255 * 2 - 1) * 128  approx
    scale_in, zp_in = inp['quantization']
    if scale_in > 0:
        img_float = img_array.astype(np.float32) / 255.0
        img_array = ((img_float / scale_in) + zp_in).astype(np.int8)
        print(f"   Input dtype: int8 (quantized, scale={scale_in}, zp={zp_in})")
    else:
        img_array = img_array.astype(np.int8)
        print("   Input dtype: int8 (no quant params — raw cast)")
else:
    img_array = img_array.astype(np.float32) / 255.0
    print("   Input dtype: float32 (normalized [0,1])")

interpreter.set_tensor(inp['index'], img_array)
interpreter.invoke()

raw_output = interpreter.get_tensor(out['index'])[0]

# Dequantize output if needed
if out['dtype'] != np.float32:
    scale_out, zp_out = out['quantization']
    predictions = (raw_output.astype(np.float32) - zp_out) * scale_out
    print(f"\n   Output dequantized: scale={scale_out}, zero_point={zp_out}")
else:
    predictions = raw_output.astype(np.float32)

# Apply softmax for proper probabilities
exp_scores = np.exp(predictions - np.max(predictions))
softmax = exp_scores / exp_scores.sum()

top3_idx = np.argsort(softmax)[-3:][::-1]

print(f"\n🌿 TOP-3 PREDICTIONS:")
print("-" * 40)
for rank, i in enumerate(top3_idx):
    conf = softmax[i] * 100
    raw  = predictions[i]
    marker = "✅" if conf >= 70 else ("⚠️ " if conf >= 50 else "❌")
    print(f"   #{rank+1} {marker} [{i:2d}] {labels[i]:<15} | softmax={conf:.2f}% | raw={raw:.4f}")

print("\n" + "=" * 60)
print("  SUMMARY FOR FLUTTER CLASSIFIER SERVICE")
print("=" * 60)
print(f"  INPUT_SIZE     = {input_h}  (height = width)")
print(f"  INPUT_DTYPE    = {inp['dtype'].__name__}")
inp_scale, inp_zp = inp['quantization']
out_scale, out_zp = out['quantization']
print(f"  INPUT_SCALE    = {inp_scale}")
print(f"  INPUT_ZP       = {inp_zp}")
print(f"  OUTPUT_SCALE   = {out_scale}")
print(f"  OUTPUT_ZP      = {out_zp}")
print(f"  NUM_CLASSES    = {num_classes}")
print("=" * 60)
