"""Pytest configuration and fixtures."""

import os
import pytest
from collections.abc import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
from app.main import app
from httpx import AsyncClient


# Override database URL for tests
@pytest.fixture(scope="session", autouse=True)
def setup_test_env():
    """Set test environment variables."""
    os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"
    os.environ["SECRET_KEY"] = "test-secret-key-for-testing-only"
    os.environ["SMS_PROVIDER"] = "dev"
    os.environ["SMS_DEBUG_ECHO"] = "true"


@pytest.fixture(scope="session")
async def test_engine():
    """Create test database engine."""
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def db_session(test_engine):
    """Create database session for tests."""
    async_session = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def override_get_db(db_session):
    """Override get_db dependency for tests."""
    async def _get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session
    
    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture
async def client(override_get_db):
    """Create test HTTP client."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def farmer_token(client: AsyncClient):
    """Create a farmer user and return access token."""
    phone = "+998901234567"
    # Send OTP
    send_response = await client.post(
        "/api/v1/auth/send-otp",
        json={"phone_number": phone, "role": "farmer"},
    )
    otp_code = send_response.json().get("debug", {}).get("otp")
    
    # Verify OTP
    verify_response = await client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": phone, "code": otp_code, "role": "farmer"},
    )
    return verify_response.json()["token"]["access_token"]


@pytest.fixture
async def shop_token(client: AsyncClient):
    """Create a shop user and return access token."""
    phone = "+998901234568"
    # Send OTP
    send_response = await client.post(
        "/api/v1/auth/send-otp",
        json={"phone_number": phone, "role": "shop"},
    )
    otp_code = send_response.json().get("debug", {}).get("otp")
    
    # Verify OTP
    verify_response = await client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": phone, "code": otp_code, "role": "shop"},
    )
    return verify_response.json()["token"]["access_token"]


@pytest.fixture
async def farmer_id(client: AsyncClient, farmer_token: str):
    """Get farmer user ID."""
    response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    return response.json()["id"]
