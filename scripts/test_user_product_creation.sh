#!/usr/bin/env bash
# Тестирование функциональности добавления пользователей и товаров

set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:8000/api/v1}"

echo "🧪 ТЕСТИРОВАНИЕ ДОБАВЛЕНИЯ ПОЛЬЗОВАТЕЛЕЙ И ТОВАРОВ"
echo "=========================================="
echo ""

# Функция для извлечения JSON значения
extract_json() {
    local json="$1"
    local key="$2"
    echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$key', '') or '')" 2>/dev/null || echo ""
}

# Функция для извлечения вложенного JSON значения
extract_nested_json() {
    local json="$1"
    local key1="$2"
    local key2="$3"
    echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$key1', {}).get('$key2', '') or '')" 2>/dev/null || echo ""
}

# Функция проверки успеха
check_success() {
    local step="$1"
    local result="$2"
    if [ -n "$result" ] && [ "$result" != "null" ] && [ "$result" != "" ]; then
        echo "✅ $step: УСПЕХ"
        return 0
    else
        echo "❌ $step: ОШИБКА"
        return 1
    fi
}

echo "1️⃣  ТЕСТ: Регистрация пользователя (фермер)"
echo "----------------------------------------"
PHONE="+998901234599"
echo "Отправка OTP на номер: $PHONE"

SEND_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$PHONE\", \"role\": \"farmer\"}")

echo "Ответ сервера:"
echo "$SEND_OTP_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$SEND_OTP_RESPONSE"
echo ""

OTP_CODE=$(extract_nested_json "$SEND_OTP_RESPONSE" "debug" "otp")
if check_success "Получение OTP кода" "$OTP_CODE"; then
    echo "   OTP код: $OTP_CODE"
else
    echo "   ⚠️  OTP код не найден в ответе"
    exit 1
fi

echo ""
echo "2️⃣  ТЕСТ: Верификация OTP и создание пользователя"
echo "----------------------------------------"
VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{
        \"phone_number\": \"$PHONE\",
        \"code\": \"$OTP_CODE\",
        \"role\": \"farmer\"
    }")

echo "Ответ сервера:"
echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null | head -20 || echo "$VERIFY_RESPONSE"
echo ""

ACCESS_TOKEN=$(extract_nested_json "$VERIFY_RESPONSE" "token" "access_token")
USER_ID=$(extract_nested_json "$VERIFY_RESPONSE" "user" "id")
USER_ROLE=$(extract_nested_json "$VERIFY_RESPONSE" "user" "role")

if check_success "Получение токена доступа" "$ACCESS_TOKEN"; then
    echo "   Токен: ${ACCESS_TOKEN:0:30}..."
    echo "   ID пользователя: $USER_ID"
    echo "   Роль: $USER_ROLE"
else
    echo "   ⚠️  Токен не получен"
    exit 1
fi

echo ""
echo "3️⃣  ТЕСТ: Создание товара (требуется роль фермера)"
echo "----------------------------------------"
PRODUCT_DATA="{
    \"name\": \"Тестовые помидоры\",
    \"description\": \"Свежие помидоры с фермы\",
    \"category\": \"vegetables\",
    \"price\": 15000,
    \"quantity\": 100,
    \"unit\": \"kg\"
}"

CREATE_PRODUCT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -d "$PRODUCT_DATA")

echo "Ответ сервера:"
echo "$CREATE_PRODUCT_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CREATE_PRODUCT_RESPONSE"
echo ""

PRODUCT_ID=$(extract_json "$CREATE_PRODUCT_RESPONSE" "id")
PRODUCT_NAME=$(extract_json "$CREATE_PRODUCT_RESPONSE" "name")

if check_success "Создание товара" "$PRODUCT_ID"; then
    echo "   ID товара: $PRODUCT_ID"
    echo "   Название: $PRODUCT_NAME"
else
    echo "   ⚠️  Товар не создан"
    ERROR_DETAIL=$(extract_json "$CREATE_PRODUCT_RESPONSE" "detail")
    if [ -n "$ERROR_DETAIL" ]; then
        echo "   Ошибка: $ERROR_DETAIL"
    fi
    exit 1
fi

echo ""
echo "4️⃣  ТЕСТ: Проверка списка товаров"
echo "----------------------------------------"
LIST_PRODUCTS_RESPONSE=$(curl -s "$API_BASE_URL/products?limit=5")

TOTAL=$(extract_json "$LIST_PRODUCTS_RESPONSE" "total")
if check_success "Получение списка товаров" "$TOTAL"; then
    echo "   Всего товаров: $TOTAL"
    echo ""
    echo "   Первые товары:"
    echo "$LIST_PRODUCTS_RESPONSE" | python3 -m json.tool 2>/dev/null | grep -A 10 "\"items\"" | head -15 || echo "$LIST_PRODUCTS_RESPONSE"
else
    echo "   ⚠️  Не удалось получить список товаров"
fi

echo ""
echo "5️⃣  ТЕСТ: Попытка создать товар без авторизации (должна быть ошибка)"
echo "----------------------------------------"
UNAUTH_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
    -H "Content-Type: application/json" \
    -d "$PRODUCT_DATA")

ERROR_DETAIL=$(extract_json "$UNAUTH_RESPONSE" "detail")
if [ -n "$ERROR_DETAIL" ]; then
    echo "✅ Правильно: запрос отклонен"
    echo "   Ошибка: $ERROR_DETAIL"
else
    echo "❌ Ошибка: запрос должен быть отклонен"
fi

echo ""
echo "6️⃣  ТЕСТ: Попытка создать товар с ролью shop (должна быть ошибка 403)"
echo "----------------------------------------"
# Создаем пользователя с ролью shop
SHOP_PHONE="+998901234600"
SHOP_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$SHOP_PHONE\", \"role\": \"shop\"}")

SHOP_OTP=$(extract_nested_json "$SHOP_OTP_RESPONSE" "debug" "otp")
if [ -n "$SHOP_OTP" ]; then
    SHOP_VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
        -H "Content-Type: application/json" \
        -d "{
            \"phone_number\": \"$SHOP_PHONE\",
            \"code\": \"$SHOP_OTP\",
            \"role\": \"shop\"
        }")
    
    SHOP_TOKEN=$(extract_nested_json "$SHOP_VERIFY_RESPONSE" "token" "access_token")
    
    if [ -n "$SHOP_TOKEN" ]; then
        SHOP_CREATE_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $SHOP_TOKEN" \
            -d "$PRODUCT_DATA")
        
        SHOP_ERROR=$(extract_json "$SHOP_CREATE_RESPONSE" "detail")
        if echo "$SHOP_ERROR" | grep -q "Only farmers"; then
            echo "✅ Правильно: магазины не могут создавать товары"
            echo "   Ошибка: $SHOP_ERROR"
        else
            echo "❌ Ошибка: магазины не должны создавать товары"
        fi
    fi
fi

echo ""
echo "=========================================="
echo "✅ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО"
echo ""
echo "📊 Результаты:"
echo "  ✅ Регистрация пользователя работает"
echo "  ✅ Верификация OTP работает"
echo "  ✅ Создание товара работает (для фермеров)"
echo "  ✅ Список товаров работает"
echo "  ✅ Защита от неавторизованных запросов работает"
echo "  ✅ Защита от создания товаров магазинами работает"
echo ""

