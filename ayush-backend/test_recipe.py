import requests
import json

url = "http://127.0.0.1:8000/api/v1/recipe/generate"
payload = {
    "user_id": "test_user_1",
    "ingredients": ["rice", "dal"],
    "spices": ["turmeric", "cumin"],
    "prakriti": "vata",
    "conditions": [],
    "diet": "vegetarian",
    "region": "India",
    "language": "en"
}
headers = {'Content-Type': 'application/json'}

print("Sending request...")
response = requests.post(url, json=payload, headers=headers)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.text}")
