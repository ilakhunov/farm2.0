# Farm Backend

FastAPI backend for the farm-to-market MVP. Includes SMS-based OTP authentication, user profile management, and scaffolding for future modules (catalog, orders, payments).

## Requirements

- Python 3.11+
- PostgreSQL 14+
- Redis 6+
- Poetry 1.6+

## Setup

```bash
cd /home/tandyvip/projects/farm2.0/backend
cp .env.example .env
# edit .env with real secrets and connection strings
poetry install
poetry run uvicorn app.main:app --reload
```

By default the API is exposed at `http://localhost:8000`, documentation is available at `/docs`.

> **Note:** `.env.example` enables `SMS_PROVIDER=dev` and `SMS_DEBUG_ECHO=true`, поэтому OTP-код возвращается в ответе `POST /auth/send-otp` — удобно для тестов без реального SMS-шлюза. Для продакшена переключите `SMS_PROVIDER` и отключите `SMS_DEBUG_ECHO`.

## Key Endpoints

- `POST /api/v1/auth/send-otp`
- `POST /api/v1/auth/verify-otp`
- `GET /api/v1/users/me`
- `PATCH /api/v1/users/me`

## Next Steps

- Integrate real SMS providers (Infobip, Beeline, Click SMS).
- Implement catalog, orders, and payments modules.
- Add Alembic migrations and CI pipelines.
