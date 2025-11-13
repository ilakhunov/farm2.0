"""Tests for products endpoints."""

import pytest
from httpx import AsyncClient
from uuid import uuid4


@pytest.mark.asyncio
async def test_create_product_as_farmer(client: AsyncClient, farmer_token: str):
    """Test creating a product as a farmer."""
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Tomatoes",
            "description": "Fresh tomatoes from farm",
            "category": "vegetables",
            "price": 15000.0,
            "quantity": 100.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test Tomatoes"
    assert data["category"] == "vegetables"
    assert data["price"] == 15000.0
    assert data["quantity"] == 100.0
    assert "id" in data


@pytest.mark.asyncio
async def test_create_product_as_shop_forbidden(client: AsyncClient, shop_token: str):
    """Test that shops cannot create products."""
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {shop_token}"},
    )
    assert response.status_code == 403
    assert "Only farmers can create products" in response.json()["detail"]


@pytest.mark.asyncio
async def test_create_product_unauthorized(client: AsyncClient):
    """Test creating a product without authentication."""
    response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_products(client: AsyncClient, farmer_token: str):
    """Test listing products."""
    # Create a product first
    await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    
    # List products
    response = await client.get("/api/v1/products")
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert len(data["items"]) > 0


@pytest.mark.asyncio
async def test_get_product_by_id(client: AsyncClient, farmer_token: str):
    """Test getting a product by ID."""
    # Create a product
    create_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = create_response.json()["id"]
    
    # Get product
    response = await client.get(f"/api/v1/products/{product_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == product_id
    assert data["name"] == "Test Product"


@pytest.mark.asyncio
async def test_get_nonexistent_product(client: AsyncClient):
    """Test getting a nonexistent product."""
    fake_id = str(uuid4())
    response = await client.get(f"/api/v1/products/{fake_id}")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_product(client: AsyncClient, farmer_token: str):
    """Test updating a product."""
    # Create a product
    create_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = create_response.json()["id"]
    
    # Update product
    response = await client.patch(
        f"/api/v1/products/{product_id}",
        json={"name": "Updated Product", "price": 150.0},
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Updated Product"
    assert data["price"] == 150.0


@pytest.mark.asyncio
async def test_delete_product(client: AsyncClient, farmer_token: str):
    """Test deleting a product."""
    # Create a product
    create_response = await client.post(
        "/api/v1/products",
        json={
            "name": "Test Product",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    product_id = create_response.json()["id"]
    
    # Delete product
    response = await client.delete(
        f"/api/v1/products/{product_id}",
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert response.status_code == 204
    
    # Verify product is deleted
    get_response = await client.get(f"/api/v1/products/{product_id}")
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_search_products(client: AsyncClient, farmer_token: str):
    """Test searching products."""
    # Create products
    await client.post(
        "/api/v1/products",
        json={
            "name": "Red Tomatoes",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    await client.post(
        "/api/v1/products",
        json={
            "name": "Green Apples",
            "category": "fruits",
            "price": 200.0,
            "quantity": 20.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    
    # Search for tomatoes
    response = await client.get("/api/v1/products?search=tomatoes")
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) > 0
    assert any("tomato" in item["name"].lower() for item in data["items"])


@pytest.mark.asyncio
async def test_filter_products_by_category(client: AsyncClient, farmer_token: str):
    """Test filtering products by category."""
    # Create products in different categories
    await client.post(
        "/api/v1/products",
        json={
            "name": "Tomatoes",
            "category": "vegetables",
            "price": 100.0,
            "quantity": 10.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    await client.post(
        "/api/v1/products",
        json={
            "name": "Apples",
            "category": "fruits",
            "price": 200.0,
            "quantity": 20.0,
            "unit": "kg",
        },
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    
    # Filter by category
    response = await client.get("/api/v1/products?category=vegetables")
    assert response.status_code == 200
    data = response.json()
    assert all(item["category"] == "vegetables" for item in data["items"])

