#!/usr/bin/env python3
"""
Скрипт для генерации демо данных:
- 1 администратор с логином и паролем
- 20 фермеров
- 20 магазинов
- Товары для каждой категории (по несколько на категорию)
"""
import asyncio
import random
import uuid
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.db.session import async_session
from app.models.product import Product, ProductCategory
from app.models.user import EntityType, User, UserRole


# Демо данные для фермеров
FARMER_NAMES = [
    "Ахмед Фермеров", "Бахтиёр Садов", "Джамшид Овощев", "Эльбек Фруктов",
    "Фарход Зернов", "Гулом Молочнов", "Хасан Мяснов", "Икром Овощев",
    "Жахонгир Садов", "Камил Фермеров", "Лутфилло Овощев", "Мухсин Фруктов",
    "Носир Зернов", "Олим Молочнов", "Парвиз Мяснов", "Равшан Овощев",
    "Сардор Садов", "Толиб Фермеров", "Умид Овощев", "Фаррух Фруктов"
]

# Демо данные для магазинов
SHOP_NAMES = [
    "Супермаркет Азия", "Магазин Фреш", "Торговый дом Зелень", "Маркет Продукты",
    "Супермаркет Узбекистан", "Магазин Фермер", "Торговый центр Еда", "Маркет Свежее",
    "Супермаркет Бахт", "Магазин Натурал", "Торговый дом Овощи", "Маркет Фрукты",
    "Супермаркет Зерно", "Магазин Молоко", "Торговый центр Мясо", "Маркет Свежесть",
    "Супермаркет Агро", "Магазин Ферма", "Торговый дом Продукт", "Маркет Качество"
]

# Товары по категориям
PRODUCTS_BY_CATEGORY = {
    ProductCategory.VEGETABLES: [
        {"name": "Помидоры", "price": 12000, "unit": "kg"},
        {"name": "Огурцы", "price": 8000, "unit": "kg"},
        {"name": "Картофель", "price": 5000, "unit": "kg"},
        {"name": "Морковь", "price": 6000, "unit": "kg"},
        {"name": "Лук", "price": 7000, "unit": "kg"},
        {"name": "Капуста", "price": 5500, "unit": "kg"},
        {"name": "Перец болгарский", "price": 15000, "unit": "kg"},
        {"name": "Баклажаны", "price": 10000, "unit": "kg"},
    ],
    ProductCategory.FRUITS: [
        {"name": "Яблоки", "price": 10000, "unit": "kg"},
        {"name": "Груши", "price": 12000, "unit": "kg"},
        {"name": "Виноград", "price": 18000, "unit": "kg"},
        {"name": "Персики", "price": 15000, "unit": "kg"},
        {"name": "Абрикосы", "price": 14000, "unit": "kg"},
        {"name": "Черешня", "price": 25000, "unit": "kg"},
        {"name": "Сливы", "price": 11000, "unit": "kg"},
        {"name": "Дыня", "price": 8000, "unit": "kg"},
    ],
    ProductCategory.GRAINS: [
        {"name": "Пшеница", "price": 3000, "unit": "kg"},
        {"name": "Рис", "price": 8000, "unit": "kg"},
        {"name": "Кукуруза", "price": 4000, "unit": "kg"},
        {"name": "Ячмень", "price": 3500, "unit": "kg"},
        {"name": "Овес", "price": 4500, "unit": "kg"},
        {"name": "Гречка", "price": 12000, "unit": "kg"},
    ],
    ProductCategory.DAIRY: [
        {"name": "Молоко", "price": 8000, "unit": "liter"},
        {"name": "Сметана", "price": 12000, "unit": "kg"},
        {"name": "Творог", "price": 15000, "unit": "kg"},
        {"name": "Сыр", "price": 25000, "unit": "kg"},
        {"name": "Йогурт", "price": 10000, "unit": "liter"},
        {"name": "Масло сливочное", "price": 35000, "unit": "kg"},
    ],
    ProductCategory.MEAT: [
        {"name": "Говядина", "price": 80000, "unit": "kg"},
        {"name": "Баранина", "price": 75000, "unit": "kg"},
        {"name": "Курица", "price": 30000, "unit": "kg"},
        {"name": "Индейка", "price": 45000, "unit": "kg"},
        {"name": "Яйца куриные", "price": 15000, "unit": "piece"},
    ],
    ProductCategory.OTHER: [
        {"name": "Мед", "price": 50000, "unit": "kg"},
        {"name": "Орехи грецкие", "price": 60000, "unit": "kg"},
        {"name": "Миндаль", "price": 80000, "unit": "kg"},
        {"name": "Фисташки", "price": 120000, "unit": "kg"},
    ],
}


async def create_admin_user(db: AsyncSession) -> tuple[str, str]:
    """Создать администратора с логином и паролем."""
    admin_username = "admin"
    admin_password = "admin123"  # В production использовать более сложный пароль
    
    # Проверить, существует ли уже админ
    stmt = select(User).where(User.username == admin_username)
    result = await db.execute(stmt)
    existing_admin = result.scalar_one_or_none()
    
    if existing_admin:
        print(f"✅ Администратор '{admin_username}' уже существует")
        return admin_username, admin_password
    
    admin = User(
        phone_number="+998901234500",
        username=admin_username,
        password_hash=get_password_hash(admin_password),
        role=UserRole.ADMIN,  # Используем enum напрямую
        email="admin@farm.uz",
        is_verified=True,
        is_active=True,
    )
    db.add(admin)
    await db.commit()
    await db.refresh(admin)
    
    print(f"✅ Создан администратор: username='{admin_username}', password='{admin_password}'")
    return admin_username, admin_password


async def create_farmers(db: AsyncSession, count: int = 20) -> list[User]:
    """Создать фермеров."""
    farmers = []
    base_phone = 901234501
    
    for i, name in enumerate(FARMER_NAMES[:count]):
        phone = f"+998{base_phone + i}"
        
        # Проверить, существует ли уже пользователь
        stmt = select(User).where(User.phone_number == phone)
        result = await db.execute(stmt)
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            farmers.append(existing_user)
            continue
        
        farmer = User(
            phone_number=phone,
            role=UserRole.FARMER,
            entity_type=EntityType.FARMER,
            legal_name=name,
            email=f"farmer{i+1}@farm.uz",
            is_verified=True,
            is_active=True,
        )
        db.add(farmer)
        farmers.append(farmer)
    
    await db.commit()
    for farmer in farmers:
        await db.refresh(farmer)
    
    print(f"✅ Создано {len(farmers)} фермеров")
    return farmers


async def create_shops(db: AsyncSession, count: int = 20) -> list[User]:
    """Создать магазины."""
    shops = []
    base_phone = 901234521
    
    for i, name in enumerate(SHOP_NAMES[:count]):
        phone = f"+998{base_phone + i}"
        
        # Проверить, существует ли уже пользователь
        stmt = select(User).where(User.phone_number == phone)
        result = await db.execute(stmt)
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            shops.append(existing_user)
            continue
        
        shop = User(
            phone_number=phone,
            role=UserRole.SHOP,
            entity_type=EntityType.LEGAL_ENTITY,
            legal_name=name,
            email=f"shop{i+1}@farm.uz",
            is_verified=True,
            is_active=True,
        )
        db.add(shop)
        shops.append(shop)
    
    await db.commit()
    for shop in shops:
        await db.refresh(shop)
    
    print(f"✅ Создано {len(shops)} магазинов")
    return shops


async def create_products(db: AsyncSession, farmers: list[User]) -> list[Product]:
    """Создать товары для каждой категории."""
    products = []
    
    # Распределить фермеров по категориям
    farmers_per_category = len(farmers) // len(ProductCategory)
    
    for category_idx, category in enumerate(ProductCategory):
        category_products = PRODUCTS_BY_CATEGORY.get(category, [])
        
        # Выбрать фермеров для этой категории
        start_idx = category_idx * farmers_per_category
        end_idx = start_idx + farmers_per_category if category_idx < len(ProductCategory) - 1 else len(farmers)
        category_farmers = farmers[start_idx:end_idx]
        
        if not category_farmers:
            continue
        
        for product_data in category_products:
            # Выбрать случайного фермера для этого товара
            farmer = random.choice(category_farmers)
            
            # Создать несколько вариантов товара с разным количеством
            for variant in range(2):  # 2 варианта каждого товара
                product = Product(
                    farmer_id=farmer.id,
                    name=f"{product_data['name']} {'премиум' if variant == 1 else 'стандарт'}",
                    description=f"Свежий {product_data['name'].lower()} от фермера {farmer.legal_name}",
                    category=category,
                    price=product_data['price'] * (1.2 if variant == 1 else 1.0),
                    quantity=random.uniform(50, 500),
                    unit=product_data['unit'],
                    is_active=True,
                )
                db.add(product)
                products.append(product)
    
    await db.commit()
    for product in products:
        await db.refresh(product)
    
    print(f"✅ Создано {len(products)} товаров")
    return products


async def main():
    """Основная функция для генерации демо данных."""
    print("🚀 Генерация демо данных...")
    print("=" * 50)
    
    async with async_session() as db:
        # Создать администратора
        admin_username, admin_password = await create_admin_user(db)
        
        # Создать фермеров
        farmers = await create_farmers(db, count=20)
        
        # Создать магазины
        shops = await create_shops(db, count=20)
        
        # Создать товары
        products = await create_products(db, farmers)
        
        print("=" * 50)
        print("✅ Демо данные успешно созданы!")
        print(f"   • Администратор: 1")
        print(f"   • Фермеры: {len(farmers)}")
        print(f"   • Магазины: {len(shops)}")
        print(f"   • Товары: {len(products)}")
        
        # Сохранить учетные данные админа в файл
        credentials_file = "ADMIN_CREDENTIALS.txt"
        with open(credentials_file, "w", encoding="utf-8") as f:
            f.write("=" * 50 + "\n")
            f.write("УЧЕТНЫЕ ДАННЫЕ АДМИНИСТРАТОРА\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Логин: {admin_username}\n")
            f.write(f"Пароль: {admin_password}\n\n")
            f.write("=" * 50 + "\n")
            f.write("ВАЖНО: Измените пароль после первого входа!\n")
            f.write("=" * 50 + "\n")
        
        print(f"\n📄 Учетные данные администратора сохранены в: {credentials_file}")


if __name__ == "__main__":
    asyncio.run(main())

