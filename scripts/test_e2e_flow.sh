#!/usr/bin/env bash
# E2E тестирование полного flow Farm Platform
set -uo pipefail  # Убрали -e чтобы скрипт продолжал выполнение при ошибках

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE_URL="${API_BASE_URL:-http://10.201.175.112:8000/api/v1}"

echo "🧪 E2E Тестирование Farm Platform"
echo "=================================="
echo "API Base URL: $API_BASE_URL"
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Счетчики
PASSED=0
FAILED=0

# Функция для проверки ответа
check_response() {
    local name=$1
    local response=$2
    local expected_status=${3:-200}
    
    if echo "$response" | grep -q "\"status_code\":$expected_status" || echo "$response" | grep -q "HTTP/1.1 $expected_status"; then
        echo -e "${GREEN}✅ PASS${NC}: $name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $name"
        echo "Response: $response"
        ((FAILED++))
        return 1
    fi
}

# Функция для извлечения значения из JSON (поддерживает вложенные ключи через точку)
extract_json() {
    local json=$1
    local key=$2
    echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
keys = '$key'.split('.')
result = data
for k in keys:
    if isinstance(result, dict):
        result = result.get(k)
    else:
        result = None
        break
print(result if result is not None else '')
" 2>/dev/null || echo ""
}

# Шаг 1: Регистрация фермера
echo "📝 Шаг 1: Регистрация фермера"
echo "----------------------------"
FARMER_PHONE="+998901234567"
echo "Отправка OTP для фермера: $FARMER_PHONE"

OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$FARMER_PHONE\", \"role\": \"farmer\"}")

OTP_CODE=$(extract_json "$OTP_RESPONSE" "debug.otp")
if [ -z "$OTP_CODE" ]; then
    OTP_CODE=$(echo "$OTP_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('debug', {}).get('otp', ''))" 2>/dev/null || echo "")
fi

if [ -z "$OTP_CODE" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить OTP код"
    echo "Response: $OTP_RESPONSE"
    ((FAILED++))
    exit 1
fi

echo "Получен OTP код: $OTP_CODE"
echo ""

# Верификация OTP фермера
echo "Верификация OTP для фермера..."
FARMER_AUTH_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$FARMER_PHONE\", \"code\": \"$OTP_CODE\", \"role\": \"farmer\"}")

FARMER_TOKEN=$(extract_json "$FARMER_AUTH_RESPONSE" "token.access_token")
FARMER_ID=$(extract_json "$FARMER_AUTH_RESPONSE" "user.id")

if [ -z "$FARMER_TOKEN" ] || [ -z "$FARMER_ID" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить токен фермера"
    echo "Response: $FARMER_AUTH_RESPONSE"
    ((FAILED++))
    exit 1
fi

echo -e "${GREEN}✅ PASS${NC}: Фермер зарегистрирован (ID: ${FARMER_ID:0:8}...)"
echo "Token получен: ${FARMER_TOKEN:0:20}..."
((PASSED++))
echo ""

# Шаг 2: Создание товара фермером
echo "📦 Шаг 2: Создание товара фермером"
echo "---------------------------------"
PRODUCT_DATA=$(cat <<EOF
{
    "name": "Тестовые помидоры",
    "description": "Свежие помидоры с фермы",
    "category": "vegetables",
    "price": 15000.0,
    "quantity": 100.0,
    "unit": "kg"
}
EOF
)

PRODUCT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $FARMER_TOKEN" \
    -d "$PRODUCT_DATA")

PRODUCT_ID=$(extract_json "$PRODUCT_RESPONSE" "id")

if [ -z "$PRODUCT_ID" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось создать товар"
    echo "Response: $PRODUCT_RESPONSE"
    ((FAILED++))
else
    echo -e "${GREEN}✅ PASS${NC}: Товар создан (ID: ${PRODUCT_ID:0:8}...)"
    ((PASSED++))
fi
echo ""

# Шаг 3: Регистрация магазина
echo "🏪 Шаг 3: Регистрация магазина"
echo "-------------------------------"
SHOP_PHONE="+998901234568"
echo "Отправка OTP для магазина: $SHOP_PHONE"

SHOP_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$SHOP_PHONE\", \"role\": \"shop\", \"entity_type\": \"legal_entity\"}")

SHOP_OTP_CODE=$(extract_json "$SHOP_OTP_RESPONSE" "debug.otp")
if [ -z "$SHOP_OTP_CODE" ]; then
    SHOP_OTP_CODE=$(echo "$SHOP_OTP_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('debug', {}).get('otp', ''))" 2>/dev/null || echo "")
fi

if [ -z "$SHOP_OTP_CODE" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить OTP код для магазина"
    echo "Response: $SHOP_OTP_RESPONSE"
    ((FAILED++))
    exit 1
fi

echo "Получен OTP код: $SHOP_OTP_CODE"

# Верификация OTP магазина
SHOP_AUTH_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{
        \"phone_number\": \"$SHOP_PHONE\",
        \"code\": \"$SHOP_OTP_CODE\",
        \"role\": \"shop\",
        \"entity_type\": \"legal_entity\",
        \"tax_id\": \"123456789\",
        \"legal_name\": \"Тестовый магазин ООО\"
    }")

SHOP_TOKEN=$(extract_json "$SHOP_AUTH_RESPONSE" "token.access_token")
SHOP_ID=$(extract_json "$SHOP_AUTH_RESPONSE" "user.id")

if [ -z "$SHOP_TOKEN" ] || [ -z "$SHOP_ID" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить токен магазина"
    echo "Response: $SHOP_AUTH_RESPONSE"
    ((FAILED++))
    exit 1
fi

echo -e "${GREEN}✅ PASS${NC}: Магазин зарегистрирован (ID: ${SHOP_ID:0:8}...)"
((PASSED++))
echo ""

# Шаг 4: Создание заказа магазином
echo "🛒 Шаг 4: Создание заказа магазином"
echo "-----------------------------------"
if [ -z "$PRODUCT_ID" ]; then
    echo -e "${YELLOW}⚠️  SKIP${NC}: Пропущено (товар не создан)"
    ((FAILED++))
else
    ORDER_DATA=$(cat <<EOF
{
    "farmer_id": "$FARMER_ID",
    "items": [
        {
            "product_id": "$PRODUCT_ID",
            "quantity": 10.0
        }
    ],
    "delivery_address": "Ташкент, ул. Тестовая, д. 1",
    "notes": "Тестовый заказ"
}
EOF
)

    ORDER_RESPONSE=$(curl -s -X POST "$API_BASE_URL/orders" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SHOP_TOKEN" \
        -d "$ORDER_DATA")

    ORDER_ID=$(extract_json "$ORDER_RESPONSE" "id")

    if [ -z "$ORDER_ID" ]; then
        echo -e "${RED}❌ FAIL${NC}: Не удалось создать заказ"
        echo "Response: $ORDER_RESPONSE"
        ((FAILED++))
    else
        echo -e "${GREEN}✅ PASS${NC}: Заказ создан (ID: ${ORDER_ID:0:8}...)"
        ((PASSED++))
    fi
fi
echo ""

# Шаг 5: Инициализация платежа
echo "💳 Шаг 5: Инициализация mock платежа"
echo "------------------------------------"
if [ -z "${ORDER_ID:-}" ]; then
    echo -e "${YELLOW}⚠️  SKIP${NC}: Пропущено (заказ не создан)"
    ((FAILED++))
else
    PAYMENT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/payments/init" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SHOP_TOKEN" \
        -d "{\"order_id\": \"$ORDER_ID\", \"provider\": \"payme\"}")

    TRANSACTION_ID=$(extract_json "$PAYMENT_RESPONSE" "transaction_id")
    PAYMENT_URL=$(extract_json "$PAYMENT_RESPONSE" "payment_url")

    if [ -z "$TRANSACTION_ID" ]; then
        echo -e "${RED}❌ FAIL${NC}: Не удалось инициализировать платеж"
        echo "Response: $PAYMENT_RESPONSE"
        ((FAILED++))
    else
        echo -e "${GREEN}✅ PASS${NC}: Платеж инициализирован (Transaction ID: ${TRANSACTION_ID:0:8}...)"
        if [ -n "$PAYMENT_URL" ]; then
            echo "Payment URL: $PAYMENT_URL"
        fi
        ((PASSED++))
    fi
fi
echo ""

# Шаг 6: Проверка доставки
echo "🚚 Шаг 6: Проверка доставки"
echo "---------------------------"
if [ -z "${ORDER_ID:-}" ]; then
    echo -e "${YELLOW}⚠️  SKIP${NC}: Пропущено (заказ не создан)"
    ((FAILED++))
else
    DELIVERY_RESPONSE=$(curl -s -X GET "$API_BASE_URL/deliveries/order/$ORDER_ID" \
        -H "Authorization: Bearer $SHOP_TOKEN")

    DELIVERY_ID=$(extract_json "$DELIVERY_RESPONSE" "id")

    if [ -z "$DELIVERY_ID" ]; then
        echo -e "${YELLOW}⚠️  INFO${NC}: Доставка еще не создана (это нормально, создается автоматически)"
    else
        echo -e "${GREEN}✅ PASS${NC}: Доставка найдена (ID: ${DELIVERY_ID:0:8}...)"
        ((PASSED++))
    fi
fi
echo ""

# Итоги
echo "=================================="
echo "📊 Итоги тестирования:"
echo "   ✅ Успешно: $PASSED"
echo "   ❌ Провалено: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Все тесты пройдены!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Некоторые тесты провалились${NC}"
    exit 1
fi

