# Farm Admin (React)

Vite + React + Tailwind админ-панель для управления пользователями, заказами и транзакциями.

## Скрипты

```bash
cd /home/tandyvip/projects/farm2.0/admin
npm install
npm run dev
```

Переменные окружения настраиваются через `.env`:

```
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

## Структура

- `src/pages/login-page.tsx` — вход по номеру телефона + OTP.
- `src/layouts` — каркасы для авторизации и рабочего пространства.
- `src/pages/users-page.tsx` — заглушка списка пользователей.
- `src/routes/router.tsx` — конфигурация маршрутов.

## TODO
- Подключить реальные вызовы `/auth/send-otp` и `/verify-otp`.
- Добавить сторедж токенов и защиту маршрутов.
- Реализовать страницы `orders`, `transactions`, `reports`.
