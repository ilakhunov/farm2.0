#!/usr/bin/env python3
"""Проверить и обновить пароль администратора."""
import asyncio

from sqlalchemy import select

from app.core.security import verify_password, get_password_hash
from app.db.session import async_session
from app.models.user import User


async def check_and_update_admin():
    """Проверить пароль администратора и обновить при необходимости."""
    async with async_session() as db:
        stmt = select(User).where(User.username == "admin")
        result = await db.execute(stmt)
        admin = result.scalar_one_or_none()
        
        if not admin:
            print("❌ Администратор не найден!")
            return
        
        print(f"✅ Администратор найден: {admin.username}")
        print(f"   Email: {admin.email}")
        print(f"   Phone: {admin.phone_number}")
        
        # Проверить разные варианты паролей
        test_passwords = ["admin123", "adminpassword", "admin"]
        print("\n🔍 Проверка паролей:")
        for pwd in test_passwords:
            is_valid = verify_password(pwd, admin.password_hash)
            print(f"   '{pwd}': {'✅ Работает' if is_valid else '❌ Не работает'}")
        
        # Обновить пароль на admin123
        new_password = "admin123"
        print(f"\n🔄 Обновление пароля на '{new_password}'...")
        admin.password_hash = get_password_hash(new_password)
        await db.commit()
        await db.refresh(admin)
        
        # Проверить новый пароль
        is_valid = verify_password(new_password, admin.password_hash)
        if is_valid:
            print(f"✅ Пароль успешно обновлен!")
            print(f"\n📋 Учетные данные:")
            print(f"   Логин: admin")
            print(f"   Пароль: {new_password}")
        else:
            print("❌ Ошибка при обновлении пароля")


if __name__ == "__main__":
    asyncio.run(check_and_update_admin())

