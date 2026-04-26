import requests
import json
import random

url = "http://127.0.0.1:8000/api/v1/recipe/generate"
payload = {
    "user_id": "test_user_1",
    "ingredients": ["rice", "dal", f"random_veg_{random.randint(1000, 9999)}"],
    "spices": ["turmeric", "cumin", "mustard"],
    "prakriti": "kapha",
    "conditions": [],
    "diet": "vegan",
    "region": "India",
    "language": "en"
}
headers = {'Content-Type': 'application/json'}

print("Sending unique request...")
response = requests.post(url, json=payload, headers=headers)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.text}")
