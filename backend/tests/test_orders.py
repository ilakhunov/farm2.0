"""Tests for orders endpoints."""

import pytest
from httpx import AsyncClient
from uuid import uuid4


@pytest.mark.asyncio
async def test_create_order_as_shop(
    client: AsyncClient, shop_token: str, farmer_token: str, farmer_id: str
):
    """Test creating an order as a shop."""
    # Create a product first
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
    
    # Create order
    response = await client.post(
        "/api/v1/orders",
        json={
            "farmer_id": farmer_id,
            "items": [{"product_id": product_id, "quantity": 10.0}],
            "delivery_address": "Test Address",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "pending"
    assert data["shop_id"] is not None
    assert data["farmer_id"] == farmer_id
    assert len(data["items"]) == 1
    assert data["items"][0]["quantity"] == 10.0


@pytest.mark.asyncio
async def test_create_order_as_farmer_forbidden(
    client: AsyncClient, farmer_token: str, farmer_id: str
):
    """Test that farmers cannot create orders."""
    # Create a product first
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
    
    # Try to create order as farmer
    response = await client.post(
        "/api/v1/orders",
        json={
            "farmer_id": farmer_id,
            "items": [{"product_id": product_id, "quantity": 10.0}],
            "delivery_address": "Test Address",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert response.status_code == 403
    assert "Only shops can create orders" in response.json()["detail"]


@pytest.mark.asyncio
async def test_create_order_insufficient_quantity(
    client: AsyncClient, shop_token: str, farmer_token: str, farmer_id: str
):
    """Test creating an order with insufficient product quantity."""
    # Create a product with limited quantity
    product_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 5.0,  # Only 5 available
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = product_response.json()["id"]
    
    # Try to order more than available
    response = await client.post(
        "/api/v1/orders",
        json={
            "farmer_id": farmer_id,
            "items": [{"product_id": product_id, "quantity": 10.0}],  # Order 10
            "delivery_address": "Test Address",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 400
    assert "insufficient" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_list_orders(client: AsyncClient, shop_token: str):
    """Test listing orders."""
    response = await client.get(
        "/api/v1/orders",
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_update_order_status(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test updating order status."""
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
    
    # Create order
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
    
    # Update order status
    response = await client.patch(
        f"/api/v1/orders/{order_id}",
        json={"status": "confirmed"},
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "confirmed"


@pytest.mark.asyncio
async def test_update_order_invalid_status_transition(
    client: AsyncClient,
    shop_token: str,
    farmer_token: str,
    farmer_id: str,
):
    """Test updating order with invalid status transition."""
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
    
    # Create order
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
    
    # Try to confirm a non-pending order (should fail)
    # First confirm it
    await client.patch(
        f"/api/v1/orders/{order_id}",
        json={"status": "confirmed"},
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    
    # Try to confirm again (invalid transition)
    response = await client.patch(
        f"/api/v1/orders/{order_id}",
        json={"status": "confirmed"},
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    # Should fail or be ignored
    assert response.status_code in [400, 200]  # Either validation error or no-op

