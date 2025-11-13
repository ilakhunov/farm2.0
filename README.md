# Farm Platform MVP

B2B платформа для прямых продаж между фермерами и магазинами в Узбекистане.

## Архитектура

- **Backend**: FastAPI (Python) с OTP-аутентификацией через SMS
- **Mobile**: Flutter приложение для фермеров и магазинов
- **Admin**: React + Vite + TailwindCSS админ-панель
- **Database**: PostgreSQL 16
- **Cache**: Redis 7

## 🚀 Быстрый старт (Автоматический)

Проект автоматически определяет IP-адрес вашего ПК/ВМ и настраивает все сервисы:

```bash
# Из корневой папки проекта
./scripts/start_project.sh
```

Скрипт автоматически:
- ✅ Определит ваш локальный IP
- ✅ Настроит переменные окружения для всех компонентов
- ✅ Запустит PostgreSQL и Redis через Docker
- ✅ Применит миграции БД
- ✅ Запустит backend API
- ✅ Запустит админ-панель
- ✅ Запустит мобильное приложение (Flutter)

## 🛑 Остановка проекта

Для корректной остановки всех сервисов:

```bash
./scripts/stop_project.sh
```

Скрипт остановки:
- ✅ Корректно завершит все процессы (backend, admin panel)
- ✅ Остановит Docker контейнеры (PostgreSQL, Redis)
- ✅ Очистит временные файлы

## 📋 Ручная настройка (если нужно)

### Автоматическая настройка окружения
```bash
./scripts/setup_environment.sh
```

### Запуск компонентов по отдельности

#### 1. Инфраструктура
```bash
docker-compose up -d
```

#### 2. Backend
```bash
cd backend
poetry install
poetry run alembic upgrade head
poetry run uvicorn app.main:app --reload --host 0.0.0.0
```

#### 3. Admin Panel
```bash
cd admin
npm install
npm run dev
```

#### 4. Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

## 🧪 Тестирование

### Backend API Tests
```bash
cd backend
poetry run pytest
```

### Flutter Analyze
```bash
cd mobile
flutter analyze
```

### Admin Lint
```bash
cd admin
npm run lint
```

### OTP Authentication (Dev Mode)

В dev-режиме OTP-код возвращается в ответе API:

```bash
curl -X POST http://[YOUR_IP]:8000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+998901234567", "role": "farmer"}'

# Ответ: {"message": "OTP sent", "debug": {"otp": "123456"}}
```

## Структура проекта

```
farm2.0/
├── backend/          # FastAPI backend
│   ├── app/
│   │   ├── api/v1/   # API endpoints (auth, users, products, orders, payments, deliveries)
│   │   ├── models/   # SQLAlchemy models (user, otp, product, order, transaction, delivery)
│   │   ├── services/ # Business logic (SMS, payments adapters)
│   │   └── core/     # Config, security, etc.
│   ├── alembic/      # Database migrations
│   └── tests/        # API tests
├── mobile/           # Flutter app
│   └── lib/
│       ├── features/ # Feature modules (auth, products, orders, payments)
│       └── core/     # Network, storage, localization
├── admin/            # React admin panel
│   └── src/
│       ├── pages/    # Page components
│       ├── lib/      # API client, auth storage
│       └── routes/   # React Router config
└── docker-compose.yml
```

## Основные эндпоинты

### Аутентификация
- `POST /api/v1/auth/send-otp` - Отправка OTP
- `POST /api/v1/auth/verify-otp` - Верификация OTP и получение токенов
- `GET /api/v1/users/me` - Профиль текущего пользователя
- `PATCH /api/v1/users/me` - Обновление профиля

### Товары
- `GET /api/v1/products` - Список товаров (с фильтрацией)
- `GET /api/v1/products/{id}` - Детали товара
- `POST /api/v1/products` - Создать товар (только фермеры)
- `PATCH /api/v1/products/{id}` - Обновить товар
- `DELETE /api/v1/products/{id}` - Удалить товар

### Заказы
- `GET /api/v1/orders` - Список заказов (фильтрация по ролям)
- `GET /api/v1/orders/{id}` - Детали заказа
- `POST /api/v1/orders` - Создать заказ (только магазины)
- `PATCH /api/v1/orders/{id}` - Обновить статус заказа

### Платежи
- `POST /api/v1/payments/init` - Инициализация платежа
- `GET /api/v1/payments/transactions` - Список транзакций
- `POST /api/v1/payments/webhooks/{provider}` - Webhook от провайдеров

### Логистика
- `GET /api/v1/deliveries/order/{order_id}` - Информация о доставке
- `PATCH /api/v1/deliveries/order/{order_id}` - Обновить доставку (только админы)

## Проверка качества кода

Все компоненты проверены на ошибки:

- ✅ **Backend**: Синтаксис Python валиден, linter без ошибок
- ✅ **Mobile**: `flutter analyze` - ошибок не найдено
- ✅ **Admin**: `npm run lint` - ошибок не найдено
- ✅ **Зависимости**: Все зависимости между стеками проверены

## Следующие шаги

### Критично для MVP
- [ ] Применить миграции БД
- [ ] Завершить интеграцию админки
- [ ] Финальное E2E тестирование

### Для production
- [ ] Интеграция реального SMS-провайдера (GetSMS)
- [ ] Реализация платежных адаптеров (Payme, Click, Arca)
- [ ] CI/CD pipeline
- [ ] Мониторинг и логирование
- [ ] Фьючерсы и финансирование

## Технологии

- Python 3.11+, FastAPI, SQLAlchemy, Alembic
- Flutter 3.3+, Dio, Equatable, url_launcher
- React 18, TypeScript, Vite, TailwindCSS, Axios
- PostgreSQL 16, Redis 7, Docker

## Скрипты

- `scripts/check_dependencies.sh` - Проверка зависимостей между стеками
- `scripts/system_health_check.sh` - Проверка системных ресурсов
- `scripts/create_initial_migration.sh` - Генерация миграций
- `scripts/optimize_system.sh` - Оптимизация системы (остановка Gradle daemons)
# farm2.0
