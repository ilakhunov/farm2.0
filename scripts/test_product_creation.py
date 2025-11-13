#!/usr/bin/env python3
"""Тест создания товара для отладки"""
import requests
import json

API_BASE = "http://10.201.175.112:8000/api/v1"

# 1. Получить OTP
print("1. Получение OTP...")
response = requests.post(f"{API_BASE}/auth/send-otp", json={
    "phone_number": "+998901234572",
    "role": "farmer"
})
print(f"   Status: {response.status_code}")
otp_data = response.json()
otp_code = otp_data.get("debug", {}).get("otp")
print(f"   OTP: {otp_code}")

# 2. Верифицировать
print("\n2. Верификация OTP...")
auth_response = requests.post(f"{API_BASE}/auth/verify-otp", json={
    "phone_number": "+998901234572",
    "code": otp_code,
    "role": "farmer"
})
print(f"   Status: {auth_response.status_code}")
auth_data = auth_response.json()
token = auth_data.get("token", {}).get("access_token")
user_id = auth_data.get("user", {}).get("id")
print(f"   Token: {token[:50] if token else 'NONE'}...")
print(f"   User ID: {user_id}")

# 3. Создать товар
print("\n3. Создание товара...")
product_data = {
    "name": "Тестовые помидоры",
    "description": "Свежие помидоры",
    "category": "vegetables",
    "price": 15000.0,
    "quantity": 100.0,
    "unit": "kg"
}
print(f"   Data: {json.dumps(product_data, indent=2)}")
product_response = requests.post(
    f"{API_BASE}/products",
    headers={"Authorization": f"Bearer {token}"},
    json=product_data
)
print(f"   Status: {product_response.status_code}")
print(f"   Response: {product_response.text}")

if product_response.status_code == 201:
    product = product_response.json()
    print(f"   ✅ Товар создан: {product.get('id')}")
else:
    print(f"   ❌ Ошибка создания товара")

