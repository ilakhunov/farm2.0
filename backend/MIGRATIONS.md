# Database Migrations

## Setup

1. Start PostgreSQL and Redis via docker-compose:
   ```bash
   cd /home/tandyvip/projects/farm2.0
   docker-compose up -d
   ```

2. Create `.env` file in `backend/`:
   ```bash
   cp .env.example .env
   # Edit .env with:
   # DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/farm
   # REDIS_URL=redis://localhost:6379/0
   ```

3. Generate initial migration:
   ```bash
   cd backend
   poetry run alembic revision --autogenerate -m "Initial migration: users and otp"
   ```

4. Apply migrations:
   ```bash
   poetry run alembic upgrade head
   ```

## Commands

- Create new migration: `poetry run alembic revision --autogenerate -m "description"`
- Apply migrations: `poetry run alembic upgrade head`
- Rollback one migration: `poetry run alembic downgrade -1`
- Show current revision: `poetry run alembic current`
