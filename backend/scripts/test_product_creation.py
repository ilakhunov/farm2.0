#!/usr/bin/env python3
"""
Диагностический скрипт для проверки создания товара фермером.
Помогает найти проблему, почему товар не сохраняется.
"""

import asyncio
import sys
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.core.config import get_settings
from app.core.security import create_token
from app.models.product import Product, ProductCategory
from app.models.user import User, UserRole
from datetime import timedelta

async def test_product_creation():
    """Тестирует создание товара с разными сценариями."""
    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=True)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    print("=" * 60)
    print("ДИАГНОСТИКА СОЗДАНИЯ ТОВАРА")
    print("=" * 60)
    
    async with async_session() as session:
        # 1. Проверка наличия фермера в БД
        print("\n1. Проверка наличия фермеров в БД:")
        stmt = select(User).where(User.role == UserRole.FARMER).limit(1)
        result = await session.execute(stmt)
        farmer = result.scalar_one_or_none()
        
        if not farmer:
            print("   ❌ Фермеры не найдены в БД!")
            print("   💡 Решение: Создайте фермера через /auth/verify-otp")
            return
        else:
            print(f"   ✅ Найден фермер: {farmer.phone_number} (ID: {farmer.id})")
            print(f"   ✅ Роль: {farmer.role.value}")
            print(f"   ✅ Активен: {farmer.is_active}")
        
        # 2. Проверка создания товара напрямую в БД
        print("\n2. Тест создания товара напрямую в БД:")
        try:
            test_product = Product(
                farmer_id=farmer.id,
                name="Тестовый товар",
                description="Описание тестового товара",
                category=ProductCategory.VEGETABLES,
                price=100.0,
                quantity=10.0,
                unit="kg",
            )
            session.add(test_product)
            await session.commit()
            await session.refresh(test_product)
            print(f"   ✅ Товар успешно создан в БД! ID: {test_product.id}")
            
            # Удаляем тестовый товар
            await session.delete(test_product)
            await session.commit()
            print("   ✅ Тестовый товар удален")
        except Exception as e:
            print(f"   ❌ Ошибка при создании товара в БД: {e}")
            await session.rollback()
            return
        
        # 3. Проверка enum значений
        print("\n3. Проверка enum значений:")
        print(f"   ProductCategory.VEGETABLES.value = '{ProductCategory.VEGETABLES.value}'")
        print(f"   ProductCategory.VEGETABLES.name = '{ProductCategory.VEGETABLES.name}'")
        
        # 4. Проверка токена для фермера
        print("\n4. Проверка генерации токена:")
        try:
            token = create_token(
                subject=str(farmer.id),
                expires_delta=timedelta(minutes=30),
            )
            print(f"   ✅ Токен сгенерирован: {token[:50]}...")
        except Exception as e:
            print(f"   ❌ Ошибка генерации токена: {e}")
    
    await engine.dispose()
    print("\n" + "=" * 60)
    print("ДИАГНОСТИКА ЗАВЕРШЕНА")
    print("=" * 60)
    print("\n💡 Возможные проблемы:")
    print("   1. Токен не передается в заголовке Authorization")
    print("   2. Токен невалидный или истек")
    print("   3. Пользователь не является фермером (role != 'farmer')")
    print("   4. Проблема с enum в SQLAlchemy (уже исправлено)")
    print("   5. Проблема с валидацией данных")

if __name__ == "__main__":
    asyncio.run(test_product_creation())


