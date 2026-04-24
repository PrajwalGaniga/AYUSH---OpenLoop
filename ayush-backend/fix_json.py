import json
from pathlib import Path

path = Path("yolo-model/yolo_classs_and_food_qna.json")
raw = path.read_text(encoding="utf-8")

# Attempt parse — if it fails, apply structural fix
try:
    data = json.loads(raw)
    print("JSON is already valid.")
except json.JSONDecodeError as e:
    print(f"JSON error found: {e}")
    # Fix: add missing closing brace for food_wisdom before the final }
    raw = raw.rstrip()
    if raw.endswith("}") and not raw.endswith("}}"):
        raw = raw[:-1] + "\n  }\n}"
    data = json.loads(raw)  # Will raise again if fix didn't work
    path.write_text(raw, encoding="utf-8")
    print("Fixed and saved.")

# Validate structure
assert "food_wisdom" in data, "Missing food_wisdom key"
assert len(data["food_wisdom"]) == 31, f"Expected 31 classes, got {len(data['food_wisdom'])}"
for cid, item in data["food_wisdom"].items():
    assert "deep_audit" in item, f"Missing deep_audit in class {cid}"
    assert "home" in item["deep_audit"], f"Missing home in class {cid}"
    assert "hotel" in item["deep_audit"], f"Missing hotel in class {cid}"
    assert "nutritional_context" in item, f"Missing nutritional_context in class {cid}"
    assert "base_ojas_delta" in item["nutritional_context"], f"Missing base_ojas_delta in class {cid}"
print(f"All {len(data['food_wisdom'])} classes validated. JSON is clean.")
