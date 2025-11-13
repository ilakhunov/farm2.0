#!/usr/bin/env bash
# Тестирование обработки ошибок

set -uo pipefail

API_BASE_URL="${API_BASE_URL:-http://10.201.175.112:8000/api/v1}"

echo "🧪 ТЕСТИРОВАНИЕ ОБРАБОТКИ ОШИБОК"
echo "==============================="
echo "API Base URL: $API_BASE_URL"
echo ""

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

check_error_response() {
    local name=$1
    local response=$2
    local expected_status=$3
    local expected_keyword=$4
    
    STATUS=$(echo "$response" | grep -o '"status_code":[0-9]*' | grep -o '[0-9]*' || echo "")
    if [ -z "$STATUS" ]; then
        # Попробуем найти статус в HTTP заголовке или detail
        if echo "$response" | grep -q "\"detail\"" || echo "$response" | grep -q "$expected_keyword"; then
            STATUS="400"
        fi
    fi
    
    if echo "$response" | grep -qi "$expected_keyword" || [ "$STATUS" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $name"
        echo "   Response: $response"
        ((FAILED++))
        return 1
    fi
}

# Тест 1: Неавторизованный запрос
echo "1️⃣  Тест: Неавторизованный запрос"
RESPONSE=$(curl -s -X GET "$API_BASE_URL/users/me")
check_error_response "Неавторизованный запрос отклонен" "$RESPONSE" "401" "Not authenticated\|Unauthorized"
echo ""

# Тест 2: Невалидный токен
echo "2️⃣  Тест: Невалидный токен"
RESPONSE=$(curl -s -X GET "$API_BASE_URL/users/me" \
    -H "Authorization: Bearer invalid_token_12345")
check_error_response "Невалидный токен отклонен" "$RESPONSE" "401" "Invalid token\|Unauthorized"
echo ""

# Тест 3: Несуществующий ресурс
echo "3️⃣  Тест: Несуществующий товар"
FAKE_ID="00000000-0000-0000-0000-000000000000"
RESPONSE=$(curl -s -X GET "$API_BASE_URL/products/$FAKE_ID")
check_error_response "Несуществующий товар возвращает 404" "$RESPONSE" "404" "Not found\|not found"
echo ""

# Тест 4: Невалидные данные при создании товара
echo "4️⃣  Тест: Невалидные данные (отсутствует обязательное поле)"
# Сначала получим токен фермера
OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d '{"phone_number": "+998901234599", "role": "farmer"}')
OTP_CODE=$(echo "$OTP_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('debug', {}).get('otp', ''))" 2>/dev/null || echo "")

if [ -n "$OTP_CODE" ]; then
    AUTH_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"+998901234599\", \"code\": \"$OTP_CODE\", \"role\": \"farmer\"}")
    TOKEN=$(echo "$AUTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', {}).get('access_token', ''))" 2>/dev/null || echo "")
    
    if [ -n "$TOKEN" ]; then
        # Попытка создать товар без обязательных полей
        RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{"name": "Test"}')
        check_error_response "Невалидные данные отклонены" "$RESPONSE" "422" "validation error\|field required"
    fi
fi
echo ""

# Тест 5: Недостаточное количество товара
echo "5️⃣  Тест: Заказ с недостаточным количеством товара"
if [ -n "${TOKEN:-}" ]; then
    # Создаем товар с ограниченным количеством
    PRODUCT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d '{
            "name": "Ограниченный товар",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 5.0,
            "unit": "kg"
        }')
    PRODUCT_ID=$(echo "$PRODUCT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null || echo "")
    FARMER_ID=$(echo "$AUTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('user', {}).get('id', ''))" 2>/dev/null || echo "")
    
    if [ -n "$PRODUCT_ID" ] && [ -n "$FARMER_ID" ]; then
        # Регистрируем магазин
        SHOP_OTP=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
            -H "Content-Type: application/json" \
            -d '{"phone_number": "+998901234598", "role": "shop"}')
        SHOP_OTP_CODE=$(echo "$SHOP_OTP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('debug', {}).get('otp', ''))" 2>/dev/null || echo "")
        
        if [ -n "$SHOP_OTP_CODE" ]; then
            SHOP_AUTH=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
                -H "Content-Type: application/json" \
                -d "{\"phone_number\": \"+998901234598\", \"code\": \"$SHOP_OTP_CODE\", \"role\": \"shop\"}")
            SHOP_TOKEN=$(echo "$SHOP_AUTH" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', {}).get('access_token', ''))" 2>/dev/null || echo "")
            
            if [ -n "$SHOP_TOKEN" ]; then
                # Пытаемся заказать больше чем есть
                ORDER_RESPONSE=$(curl -s -X POST "$API_BASE_URL/orders" \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $SHOP_TOKEN" \
                    -d "{
                        \"farmer_id\": \"$FARMER_ID\",
                        \"items\": [{\"product_id\": \"$PRODUCT_ID\", \"quantity\": 100.0}],
                        \"delivery_address\": \"Test\"
                    }")
                check_error_response "Недостаточное количество товара" "$ORDER_RESPONSE" "400" "insufficient\|not enough"
            fi
        fi
    fi
fi
echo ""

# Тест 6: Невалидный номер телефона
echo "6️⃣  Тест: Невалидный номер телефона"
RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d '{"phone_number": "invalid", "role": "farmer"}')
check_error_response "Невалидный номер телефона отклонен" "$RESPONSE" "400" "validation error\|invalid phone"
echo ""

# Итоги
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ИТОГИ ТЕСТИРОВАНИЯ ОБРАБОТКИ ОШИБОК:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Успешно: $PASSED"
echo "   ❌ Провалено: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Все тесты обработки ошибок пройдены!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Некоторые тесты провалились${NC}"
    exit 1
fi

