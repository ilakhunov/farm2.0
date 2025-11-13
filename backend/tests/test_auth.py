"""Tests for OTP authentication endpoints."""

import pytest


@pytest.mark.asyncio
async def test_send_otp_success(client):
    """Test successful OTP sending."""
    response = await client.post(
        "/api/v1/auth/send-otp",
        json={"phone_number": "+998901234567", "role": "farmer"},
    )
    assert response.status_code == 202
    data = response.json()
    assert "message" in data
    assert data["message"] == "OTP sent"
    # In dev mode, debug OTP should be present
    if "debug" in data:
        assert "otp" in data["debug"]
        assert len(data["debug"]["otp"]) == 6


@pytest.mark.asyncio
async def test_send_otp_invalid_phone(client):
    """Test OTP sending with invalid phone number."""
    response = await client.post(
        "/api/v1/auth/send-otp",
        json={"phone_number": "invalid", "role": "farmer"},
    )
    # Pydantic validation returns 422 for invalid input
    assert response.status_code in [400, 422]


@pytest.mark.asyncio
async def test_verify_otp_without_sending(client):
    """Test OTP verification without sending OTP first."""
    response = await client.post(
        "/api/v1/auth/verify-otp",
        json={"phone_number": "+998901234567", "code": "123456", "role": "farmer"},
    )
    assert response.status_code == 400
    # The error message can be either "OTP not found" or "Invalid OTP code" depending on timing
    detail = response.json()["detail"]
    assert "OTP" in detail or "Invalid" in detail


@pytest.mark.asyncio
async def test_full_otp_flow(client, db_session):
    """Test complete OTP authentication flow."""
    from app.models.otp import PhoneOTP
    from sqlalchemy import delete
    
    phone = "+998901234567"
    
    # Clear any existing OTPs to avoid rate limiting
    await db_session.execute(delete(PhoneOTP).where(PhoneOTP.phone_number == phone))
    await db_session.commit()
    
    # Step 1: Send OTP
    send_response = await client.post(
        "/api/v1/auth/send-otp",
        json={"phone_number": phone, "role": "farmer"},
    )
    assert send_response.status_code == 202, f"Failed to send OTP: {send_response.json()}"
    send_data = send_response.json()
    
    # Get OTP code (in dev mode)
    otp_code = None
    if "debug" in send_data and "otp" in send_data["debug"]:
        otp_code = send_data["debug"]["otp"]
    
    if otp_code:
        # Step 2: Verify OTP
        verify_response = await client.post(
            "/api/v1/auth/verify-otp",
            json={"phone_number": phone, "code": otp_code, "role": "farmer"},
        )
        assert verify_response.status_code == 200
        verify_data = verify_response.json()
        assert "token" in verify_data
        assert "user" in verify_data
        assert verify_data["user"]["phone_number"] == phone
        assert verify_data["user"]["role"] == "farmer"
        assert "access_token" in verify_data["token"]
        assert "refresh_token" in verify_data["token"]
