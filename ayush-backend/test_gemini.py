import os
import google.generativeai as genai

api_key = "AIzaSyDS6EGj5nF2tgNKthFhtrbnUNueaWP-H-w"
genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-2.5-flash')

try:
    response = model.generate_content("Say hello")
    print(f"SUCCESS: {response.text}")
except Exception as e:
    print(f"ERROR: {e}")
