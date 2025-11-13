#!/usr/bin/env bash
# Комплексное тестирование всех ролей (farmer, shop, admin)

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE_URL="${API_BASE_URL:-http://10.201.175.112:8000/api/v1}"

echo "🧪 ТЕСТИРОВАНИЕ ВСЕХ РОЛЕЙ"
echo "=========================="
echo "API Base URL: $API_BASE_URL"
echo ""

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Счетчики
PASSED=0
FAILED=0

# Функция для извлечения JSON значения
extract_json() {
    local json=$1
    local key=$2
    echo "$json" | python3 -c "
import sys, json
try:
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
except:
    print('')
" 2>/dev/null || echo ""
}

# Функция проверки
check_success() {
    local name=$1
    local result=$2
    if [ -n "$result" ] && [ "$result" != "null" ] && [ "$result" != "" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}: $name"
        ((FAILED++))
        return 1
    fi
}

# ============================================
# ТЕСТ 1: FARMER ROLE
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ТЕСТ 1: FARMER ROLE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

FARMER_PHONE="+998901234567"
echo "📱 Регистрация фермера: $FARMER_PHONE"

# Отправка OTP
OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$FARMER_PHONE\", \"role\": \"farmer\", \"entity_type\": \"farmer\"}")

OTP_CODE=$(extract_json "$OTP_RESPONSE" "debug.otp")
if [ -z "$OTP_CODE" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить OTP"
    ((FAILED++))
    exit 1
fi

echo "   OTP код: $OTP_CODE"

# Верификация OTP
FARMER_AUTH=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$FARMER_PHONE\", \"code\": \"$OTP_CODE\", \"role\": \"farmer\", \"entity_type\": \"farmer\"}")

FARMER_TOKEN=$(extract_json "$FARMER_AUTH" "token.access_token")
FARMER_ID=$(extract_json "$FARMER_AUTH" "user.id")
FARMER_ROLE=$(extract_json "$FARMER_AUTH" "user.role")

check_success "Регистрация фермера" "$FARMER_TOKEN"
echo "   ID: ${FARMER_ID:0:8}..."
echo "   Роль: $FARMER_ROLE"
echo ""

# Фермер может создавать товары
echo "📦 Тест: Фермер создает товар"
PRODUCT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/products" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $FARMER_TOKEN" \
    -d '{
        "name": "Тестовые помидоры",
        "description": "Свежие помидоры",
        "category": "vegetables",
        "price": 15000.0,
        "quantity": 100.0,
        "unit": "kg"
    }')

PRODUCT_ID=$(extract_json "$PRODUCT_RESPONSE" "id")
check_success "Создание товара фермером" "$PRODUCT_ID"
echo ""

# Фермер НЕ может создавать заказы
echo "🛒 Тест: Фермер НЕ может создавать заказы"
SHOP_PHONE_TEMP="+998901234568"
SHOP_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$SHOP_PHONE_TEMP\", \"role\": \"shop\"}")
SHOP_OTP_CODE=$(extract_json "$SHOP_OTP_RESPONSE" "debug.otp")
SHOP_AUTH_TEMP=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$SHOP_PHONE_TEMP\", \"code\": \"$SHOP_OTP_CODE\", \"role\": \"shop\"}")
SHOP_ID_TEMP=$(extract_json "$SHOP_AUTH_TEMP" "user.id")

ORDER_FORBIDDEN=$(curl -s -X POST "$API_BASE_URL/orders" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $FARMER_TOKEN" \
    -d "{\"farmer_id\": \"$FARMER_ID\", \"items\": [{\"product_id\": \"$PRODUCT_ID\", \"quantity\": 10.0}], \"delivery_address\": \"Test\"}")

if echo "$ORDER_FORBIDDEN" | grep -q "Only shops can create orders" || echo "$ORDER_FORBIDDEN" | grep -q "403"; then
    echo -e "${GREEN}✅ PASS${NC}: Фермер не может создавать заказы (правильно)"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: Фермер смог создать заказ (неправильно)"
    ((FAILED++))
fi
echo ""

# ============================================
# ТЕСТ 2: SHOP ROLE
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ТЕСТ 2: SHOP ROLE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

SHOP_PHONE="+998901234568"
echo "🏪 Регистрация магазина: $SHOP_PHONE"

# Отправка OTP
SHOP_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$SHOP_PHONE\", \"role\": \"shop\", \"entity_type\": \"legal_entity\"}")

SHOP_OTP_CODE=$(extract_json "$SHOP_OTP_RESPONSE" "debug.otp")
if [ -z "$SHOP_OTP_CODE" ]; then
    echo -e "${RED}❌ FAIL${NC}: Не удалось получить OTP для магазина"
    ((FAILED++))
else
    echo "   OTP код: $SHOP_OTP_CODE"
    
    # Верификация OTP
    SHOP_AUTH=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
        -H "Content-Type: application/json" \
        -d "{
            \"phone_number\": \"$SHOP_PHONE\",
            \"code\": \"$SHOP_OTP_CODE\",
            \"role\": \"shop\",
            \"entity_type\": \"legal_entity\",
            \"tax_id\": \"123456789\",
            \"legal_name\": \"Тестовый магазин ООО\"
        }")
    
    SHOP_TOKEN=$(extract_json "$SHOP_AUTH" "token.access_token")
    SHOP_ID=$(extract_json "$SHOP_AUTH" "user.id")
    SHOP_ROLE=$(extract_json "$SHOP_AUTH" "user.role")
    
    check_success "Регистрация магазина" "$SHOP_TOKEN"
    echo "   ID: ${SHOP_ID:0:8}..."
    echo "   Роль: $SHOP_ROLE"
    echo ""
    
    # Магазин НЕ может создавать товары
    echo "📦 Тест: Магазин НЕ может создавать товары"
    SHOP_PRODUCT_FORBIDDEN=$(curl -s -X POST "$API_BASE_URL/products" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $SHOP_TOKEN" \
        -d '{
            "name": "Товар от магазина",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg"
        }')
    
    if echo "$SHOP_PRODUCT_FORBIDDEN" | grep -q "Only farmers can create products" || echo "$SHOP_PRODUCT_FORBIDDEN" | grep -q "403"; then
        echo -e "${GREEN}✅ PASS${NC}: Магазин не может создавать товары (правильно)"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: Магазин смог создать товар (неправильно)"
        ((FAILED++))
    fi
    echo ""
    
    # Магазин может создавать заказы
    echo "🛒 Тест: Магазин создает заказ"
    if [ -n "$PRODUCT_ID" ] && [ -n "$FARMER_ID" ]; then
        ORDER_RESPONSE=$(curl -s -X POST "$API_BASE_URL/orders" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $SHOP_TOKEN" \
            -d "{
                \"farmer_id\": \"$FARMER_ID\",
                \"items\": [{\"product_id\": \"$PRODUCT_ID\", \"quantity\": 10.0}],
                \"delivery_address\": \"Ташкент, ул. Тестовая, д. 1\",
                \"notes\": \"Тестовый заказ\"
            }")
        
        ORDER_ID=$(extract_json "$ORDER_RESPONSE" "id")
        check_success "Создание заказа магазином" "$ORDER_ID"
        echo ""
        
        # Магазин может инициализировать платеж
        if [ -n "$ORDER_ID" ]; then
            echo "💳 Тест: Магазин инициализирует платеж"
            PAYMENT_RESPONSE=$(curl -s -X POST "$API_BASE_URL/payments/init" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $SHOP_TOKEN" \
                -d "{\"order_id\": \"$ORDER_ID\", \"provider\": \"payme\"}")
            
            TRANSACTION_ID=$(extract_json "$PAYMENT_RESPONSE" "transaction_id")
            check_success "Инициализация платежа" "$TRANSACTION_ID"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  SKIP${NC}: Пропущено (товар или фермер не создан)"
        ((FAILED++))
    fi
fi

# ============================================
# ТЕСТ 3: ADMIN ROLE (если есть)
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ТЕСТ 3: ADMIN ROLE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ADMIN_PHONE="+998901234569"
echo "👑 Попытка регистрации админа: $ADMIN_PHONE"

# Отправка OTP
ADMIN_OTP_RESPONSE=$(curl -s -X POST "$API_BASE_URL/auth/send-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone_number\": \"$ADMIN_PHONE\", \"role\": \"admin\"}")

ADMIN_OTP_CODE=$(extract_json "$ADMIN_OTP_RESPONSE" "debug.otp")
if [ -n "$ADMIN_OTP_CODE" ]; then
    echo "   OTP код: $ADMIN_OTP_CODE"
    
    ADMIN_AUTH=$(curl -s -X POST "$API_BASE_URL/auth/verify-otp" \
        -H "Content-Type: application/json" \
        -d "{\"phone_number\": \"$ADMIN_PHONE\", \"code\": \"$ADMIN_OTP_CODE\", \"role\": \"admin\"}")
    
    ADMIN_TOKEN=$(extract_json "$ADMIN_AUTH" "token.access_token")
    ADMIN_ROLE=$(extract_json "$ADMIN_AUTH" "user.role")
    
    if [ -n "$ADMIN_TOKEN" ]; then
        check_success "Регистрация админа" "$ADMIN_TOKEN"
        echo "   Роль: $ADMIN_ROLE"
        echo ""
        
        # Админ может просматривать всех пользователей
        echo "👥 Тест: Админ просматривает список пользователей"
        USERS_RESPONSE=$(curl -s -X GET "$API_BASE_URL/users" \
            -H "Authorization: Bearer $ADMIN_TOKEN")
        
        USERS_COUNT=$(echo "$USERS_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data) if isinstance(data, list) else 0)" 2>/dev/null || echo "0")
        if [ "$USERS_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✅ PASS${NC}: Админ может просматривать пользователей (найдено: $USERS_COUNT)"
            ((PASSED++))
        else
            echo -e "${YELLOW}⚠️  INFO${NC}: Список пользователей пуст или недоступен"
        fi
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  INFO${NC}: Админ не может быть создан через OTP (это нормально)"
fi

# ============================================
# ИТОГИ
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "📊 ИТОГИ ТЕСТИРОВАНИЯ РОЛЕЙ:"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "   ✅ Успешно: $PASSED"
echo "   ❌ Провалено: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Все тесты ролей пройдены!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Некоторые тесты провалились${NC}"
    exit 1
fi

