"""Tests for deliveries endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_delivery_by_order(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test getting delivery by order ID."""
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
    
    # Create an order (delivery should be created automatically)
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
    
    # Get delivery
    response = await client.get(
        f"/api/v1/deliveries/order/{order_id}",
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["order_id"] == order_id
    assert data["status"] == "pending"
    assert data["delivery_address"] == "Test Address"


@pytest.mark.asyncio
async def test_update_delivery(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test updating delivery information."""
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
    
    # Update delivery
    response = await client.patch(
        f"/api/v1/deliveries/order/{order_id}",
        json={
            "status": "assigned",
            "courier_name": "Test Courier",
            "courier_phone": "+998901234569",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "assigned"
    assert data["courier_name"] == "Test Courier"
    assert data["courier_phone"] == "+998901234569"


@pytest.mark.asyncio
async def test_get_delivery_nonexistent_order(
    client: AsyncClient, shop_token: str
):
    """Test getting delivery for nonexistent order."""
    fake_order_id = "00000000-0000-0000-0000-000000000000"
    response = await client.get(
        f"/api/v1/deliveries/order/{fake_order_id}",
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 404

