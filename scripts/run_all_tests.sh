#!/usr/bin/env bash
# Запуск всех тестов

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🧪 ЗАПУСК ВСЕХ ТЕСТОВ"
echo "===================="
echo ""

TOTAL_PASSED=0
TOTAL_FAILED=0

# Функция запуска теста
run_test() {
    local test_name=$1
    local test_script=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ -f "$test_script" ]; then
        if bash "$test_script"; then
            echo -e "\n✅ $test_name: ПРОЙДЕН\n"
            ((TOTAL_PASSED++))
        else
            echo -e "\n❌ $test_name: ПРОВАЛЕН\n"
            ((TOTAL_FAILED++))
        fi
    else
        echo "⚠️  Скрипт не найден: $test_script"
        ((TOTAL_FAILED++))
    fi
    
    echo ""
    sleep 2
}

# 1. Unit тесты
echo "1️⃣  Backend Unit Тесты"
echo "-------------------"
cd "$PROJECT_ROOT/backend"
if poetry run pytest tests/ -v --tb=short 2>&1 | tee /tmp/unit_tests.log; then
    echo -e "\n✅ Unit тесты: ПРОЙДЕНЫ\n"
    ((TOTAL_PASSED++))
else
    echo -e "\n❌ Unit тесты: ПРОВАЛЕНЫ\n"
    ((TOTAL_FAILED++))
fi
cd "$PROJECT_ROOT"
echo ""

# 2. E2E тест полного flow
run_test "E2E Тест полного flow" "$PROJECT_ROOT/scripts/test_e2e_flow.sh"

# 3. Тест всех ролей
run_test "Тест всех ролей" "$PROJECT_ROOT/scripts/test_all_roles.sh"

# 4. Тест обработки ошибок
run_test "Тест обработки ошибок" "$PROJECT_ROOT/scripts/test_error_handling.sh"

# 5. Тест создания пользователей и товаров
run_test "Тест создания пользователей и товаров" "$PROJECT_ROOT/scripts/test_user_product_creation.sh"

# Итоги
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ИТОГОВЫЕ РЕЗУЛЬТАТЫ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Пройдено тестов: $TOTAL_PASSED"
echo "   ❌ Провалено тестов: $TOTAL_FAILED"
echo ""

if [ $TOTAL_FAILED -eq 0 ]; then
    echo "🎉 Все тесты пройдены успешно!"
    exit 0
else
    echo "⚠️  Некоторые тесты провалились"
    exit 1
fi

