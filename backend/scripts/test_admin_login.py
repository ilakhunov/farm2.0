#!/usr/bin/env python3
"""Тестировать логин администратора через API."""
import asyncio
import sys

from sqlalchemy import select

from app.core.security import verify_password
from app.db.session import async_session
from app.models.user import User


async def test_admin_login():
    """Проверить логин администратора."""
    async with async_session() as db:
        stmt = select(User).where(User.username == "admin")
        result = await db.execute(stmt)
        admin = result.scalar_one_or_none()
        
        if not admin:
            print("❌ Администратор не найден в базе данных!")
            print("   Запустите: poetry run python scripts/generate_demo_data.py")
            sys.exit(1)
        
        print("✅ Администратор найден в базе данных")
        print(f"   Username: {admin.username}")
        print(f"   Email: {admin.email}")
        print(f"   Phone: {admin.phone_number}")
        print(f"   Role: {admin.role.value}")
        print(f"   Is Active: {admin.is_active}")
        print(f"   Is Verified: {admin.is_verified}")
        print(f"   Has Password Hash: {admin.password_hash is not None}")
        
        # Проверить пароль
        test_password = "admin123"
        print(f"\n🔍 Проверка пароля '{test_password}':")
        if not admin.password_hash:
            print("   ❌ Пароль не установлен!")
            print("   Запустите: poetry run python scripts/check_admin_password.py")
            sys.exit(1)
        
        is_valid = verify_password(test_password, admin.password_hash)
        if is_valid:
            print(f"   ✅ Пароль '{test_password}' работает!")
            print("\n📋 Учетные данные для входа:")
            print(f"   Логин: {admin.username}")
            print(f"   Пароль: {test_password}")
            print("\n💡 Если логин не работает в админ-панели:")
            print("   1. Проверьте, что backend запущен (http://localhost:8000)")
            print("   2. Проверьте URL API в admin/.env")
            print("   3. Проверьте консоль браузера на ошибки")
            print("   4. Убедитесь, что используете правильный логин и пароль")
        else:
            print(f"   ❌ Пароль '{test_password}' не работает!")
            print("   Запустите: poetry run python scripts/check_admin_password.py")
            sys.exit(1)


if __name__ == "__main__":
    asyncio.run(test_admin_login())

