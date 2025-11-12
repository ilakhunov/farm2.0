# Исправление CSP ошибки

## Проблема
Vite в режиме разработки использует `eval()` для Hot Module Replacement (HMR), 
что блокируется строгой политикой безопасности контента (CSP).

## Решение

### Вариант 1: Meta tag в HTML (уже добавлен)
Добавлен meta tag в `index.html` с разрешением `unsafe-eval` для разработки.

### Вариант 2: Заголовки в Vite config (уже добавлен)
Настроены заголовки CSP в `vite.config.ts` для dev сервера.

## Если проблема сохраняется:

1. **Проверьте расширения браузера:**
   - Отключите расширения безопасности (например, Privacy Badger, uBlock Origin)
   - Попробуйте в режиме инкогнито

2. **Проверьте настройки браузера:**
   - Chrome: chrome://settings/security
   - Firefox: about:preferences#privacy

3. **Альтернативное решение:**
   Если meta tag конфликтует, удалите его из index.html и оставьте только настройку в vite.config.ts

## Для Production:
⚠️ В production НЕ используйте `unsafe-eval`!
Настройте строгий CSP без unsafe-eval.
