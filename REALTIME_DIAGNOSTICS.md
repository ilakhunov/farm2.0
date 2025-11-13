# 📊 Реал-тайм диагностика проекта

**Дата создания:** 2025-11-13

## 🎯 Обзор

Набор инструментов для мониторинга и диагностики проекта Farm Platform в реальном времени.

## 📋 Доступные инструменты

### 1. Мониторинг в реальном времени

**Скрипт:** `./scripts/monitor_realtime.sh`

Показывает полную информацию о состоянии всех сервисов проекта:

- ✅ Статус всех сервисов (Backend, Admin, Mobile, PostgreSQL, Redis)
- 📈 Метрики API (количество товаров, заказов, пользователей)
- 🖥️ Использование ресурсов (CPU, память для каждого процесса)
- 🐳 Статус Docker контейнеров
- ⚠️ Последние ошибки из логов
- 🔌 Статус портов

#### Использование:

```bash
# Непрерывный мониторинг (обновление каждые 5 секунд)
./scripts/monitor_realtime.sh

# Одноразовая проверка
./scripts/monitor_realtime.sh --once
```

**Пример вывода:**
```
════════════════════════════════════════
  REAL-TIME DIAGNOSTICS
  2025-11-13 17:23:20
════════════════════════════════════════

📊 SERVICE STATUS:
✅ Backend API
✅ Admin Panel
✅ Mobile App
✅ PostgreSQL
✅ Redis

📈 API METRICS:
  • Products in DB: 18
  • Orders in DB: 0
  • Users in DB: 5

🖥️  PROCESSES:
  • Backend (PID 9301): CPU 0.1%, MEM 0.1%
  • Admin Panel (PID 9331): CPU 0.0%, MEM 0.7%
  • Mobile App (PID 163819): CPU 0.0%, MEM 0.5%

🐳 DOCKER CONTAINERS:
  • PostgreSQL: running
  • Redis: running

⚠️  RECENT ERRORS (last 3):
  Backend: нет ошибок
  Mobile: нет ошибок

🔌 PORTS:
  • 8000 (Backend): ✅ занят
  • 5182 (Admin): ✅ занят
```

### 2. Просмотр логов в реальном времени

**Скрипт:** `./scripts/watch_logs.sh`

Позволяет просматривать логи различных компонентов в реальном времени.

#### Использование:

```bash
# Все логи одновременно
./scripts/watch_logs.sh

# Логи Backend API
./scripts/watch_logs.sh backend
# или
./scripts/watch_logs.sh b

# Логи Admin Panel
./scripts/watch_logs.sh admin
# или
./scripts/watch_logs.sh a

# Логи Mobile App
./scripts/watch_logs.sh mobile
# или
./scripts/watch_logs.sh m

# Логи Docker контейнеров
./scripts/watch_logs.sh docker
# или
./scripts/watch_logs.sh d

# Только ошибки из всех логов
./scripts/watch_logs.sh errors
# или
./scripts/watch_logs.sh e
```

**Типы логов:**
- `backend`, `b` - Логи Backend API (`/tmp/farm_backend.log`)
- `admin`, `a` - Логи Admin Panel (`/tmp/farm_admin.log`)
- `mobile`, `m` - Логи Mobile App (`/tmp/farm_mobile.log`)
- `docker`, `d` - Логи Docker контейнеров (`docker-compose logs`)
- `errors`, `e` - Только ошибки из всех логов
- `all` (по умолчанию) - Все логи одновременно

**Выход:** Нажмите `Ctrl+C` для выхода

### 3. Быстрая проверка здоровья

**Скрипт:** `./scripts/health_check.sh`

Быстрая проверка статуса всех сервисов без детальной информации.

#### Использование:

```bash
./scripts/health_check.sh
```

**Пример вывода:**
```
🏥 HEALTH CHECK
==============

Backend API: ✅ OK
Products API: ✅ OK
Backend Process: ✅ Running
Admin Panel: ✅ Running
Mobile App: ✅ Running
PostgreSQL: ✅ Running
Redis: ✅ Running

✅ Health check complete!
```

## 🔧 Прямой доступ к логам

Если вы хотите просматривать логи напрямую без скриптов:

```bash
# Backend API
tail -f /tmp/farm_backend.log

# Admin Panel
tail -f /tmp/farm_admin.log

# Mobile App
tail -f /tmp/farm_mobile.log

# Docker контейнеры
docker-compose logs -f

# Только PostgreSQL
docker logs -f farm_postgres

# Только Redis
docker logs -f farm_redis
```

## 📊 Мониторинг метрик

### API метрики

```bash
# Количество товаров
curl -s "http://localhost:8000/api/v1/products?limit=1" | python3 -c "import sys, json; print(json.load(sys.stdin)['total'])"

# Health check
curl http://localhost:8000/health
```

### База данных

```bash
# Количество пользователей
docker exec farm_postgres psql -U postgres -d farm -t -c "SELECT COUNT(*) FROM users;"

# Количество товаров
docker exec farm_postgres psql -U postgres -d farm -t -c "SELECT COUNT(*) FROM products;"

# Количество заказов
docker exec farm_postgres psql -U postgres -d farm -t -c "SELECT COUNT(*) FROM orders;"
```

### Процессы

```bash
# Статус Backend
ps aux | grep "[u]vicorn app.main:app"

# Статус Admin Panel
ps aux | grep "[v]ite"

# Статус Mobile App
ps aux | grep "[f]lutter run"
```

## 🎯 Рекомендации по использованию

### Для разработки:

1. **Запустите мониторинг в отдельном терминале:**
   ```bash
   ./scripts/monitor_realtime.sh
   ```

2. **В другом терминале следите за ошибками:**
   ```bash
   ./scripts/watch_logs.sh errors
   ```

3. **Периодически проверяйте здоровье системы:**
   ```bash
   ./scripts/health_check.sh
   ```

### Для отладки:

1. **Если возникла проблема с Backend:**
   ```bash
   ./scripts/watch_logs.sh backend
   ```

2. **Если проблема с Mobile App:**
   ```bash
   ./scripts/watch_logs.sh mobile
   ```

3. **Для просмотра всех ошибок:**
   ```bash
   ./scripts/watch_logs.sh errors
   ```

## 📝 Примечания

- Все скрипты используют цветной вывод для лучшей читаемости
- Мониторинг обновляется каждые 5 секунд
- Логи сохраняются в `/tmp/` директории
- Для выхода из режима реального времени нажмите `Ctrl+C`

## 🔄 Интеграция с CI/CD

Скрипт `health_check.sh` можно использовать в CI/CD пайплайнах:

```bash
#!/bin/bash
if ./scripts/health_check.sh; then
    echo "All services are healthy"
    exit 0
else
    echo "Some services are down"
    exit 1
fi
```

## 📚 Дополнительные ресурсы

- **Логи:** `/tmp/farm_*.log`
- **Docker логи:** `docker-compose logs`
- **API документация:** http://localhost:8000/docs
- **Health endpoint:** http://localhost:8000/health

---

**Статус:** ✅ Все инструменты готовы к использованию!

