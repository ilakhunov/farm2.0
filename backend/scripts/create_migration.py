#!/usr/bin/env python3
"""Create Alembic migration script."""
import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(__file__))

try:
    from alembic.config import Config
    from alembic import command
    
    alembic_cfg = Config("alembic.ini")
    command.revision(alembic_cfg, autogenerate=True, message="Initial migration: all models")
    print("✓ Миграция создана успешно")
except ImportError as e:
    print(f"❌ Ошибка импорта: {e}")
    print("\nУстановите зависимости:")
    print("  pip install alembic sqlalchemy asyncpg")
    sys.exit(1)
except Exception as e:
    print(f"❌ Ошибка создания миграции: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

