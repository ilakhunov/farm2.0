"""Tests for payments endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_init_payment(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test initializing a payment."""
    # Create a product
    product_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 100.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = product_response.json()["id"]
    
    # Create an order
    order_response = await client.post(
        "/api/v1/orders",
        json={
            "farmer_id": farmer_id,
            "items": [{"product_id": product_id, "quantity": 10.0}],
            "delivery_address": "Test Address",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    order_id = order_response.json()["id"]
    
    # Init payment
    response = await client.post(
        "/api/v1/payments/init",
        json={"order_id": order_id, "provider": "payme"},
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "transaction_id" in data
    assert "payment_url" in data


@pytest.mark.asyncio
async def test_init_payment_unauthorized(client: AsyncClient):
    """Test initializing payment without authentication."""
    fake_order_id = "00000000-0000-0000-0000-000000000000"
    response = await client.post(
        "/api/v1/payments/init",
        json={"order_id": fake_order_id, "provider": "payme"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_init_payment_nonexistent_order(
    client: AsyncClient, shop_token: str
):
    """Test initializing payment for nonexistent order."""
    fake_order_id = "00000000-0000-0000-0000-000000000000"
    response = await client.post(
        "/api/v1/payments/init",
        json={"order_id": fake_order_id, "provider": "payme"},
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_init_payment_mock_mode(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test that mock payment mode works."""
    # Create a product
    product_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 100.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = product_response.json()["id"]
    
    # Create an order
    order_response = await client.post(
        "/api/v1/orders",
        json={
            "farmer_id": farmer_id,
            "items": [{"product_id": product_id, "quantity": 10.0}],
            "delivery_address": "Test Address",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    order_id = order_response.json()["id"]
    
    # Init payment with different providers (all should use mock)
    for provider in ["payme", "click", "arca"]:
        response = await client.post(
            "/api/v1/payments/init",
            json={"order_id": order_id, "provider": provider},
            headers={"Authorization": f"Bearer {shop_token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "transaction_id" in data
        assert "payment_url" in data
        # In mock mode, payment_url should contain mock-payment.com
        assert "mock" in data["payment_url"].lower() or "mock" in str(data).lower()

