"""Pytest configuration and fixtures."""

import os
from collections.abc import AsyncGenerator

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool
from httpx import AsyncClient, ASGITransport

from app.db.session import Base, get_db
from app.main import app


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


@pytest.fixture(scope="session")
def test_session_factory(test_engine):
    """Create session factory for tests."""
    return async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture
async def db_session(test_session_factory):
    """Create database session for tests."""
    async with test_session_factory() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(test_session_factory):
    """Create test HTTP client with overridden database dependency."""
    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with test_session_factory() as session:
            yield session
            await session.rollback()

    app.dependency_overrides[get_db] = override_get_db
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    
    # Clean up dependency override after test
    app.dependency_overrides.clear()
