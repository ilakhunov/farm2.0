from functools import lru_cache
from typing import List

from pydantic import AnyHttpUrl, Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Farm Platform Backend"
    api_v1_prefix: str = "/api/v1"
    secret_key: str = Field(..., alias="SECRET_KEY")
    access_token_expire_minutes: int = 30
    refresh_token_expire_minutes: int = 60 * 24 * 30
    database_url: str = Field(..., alias="DATABASE_URL")
    redis_url: str = Field(..., alias="REDIS_URL")
    allowed_hosts: List[AnyHttpUrl] = []
    otp_expiration_minutes: int = 5
    otp_attempt_limit: int = 5
    otp_resend_interval_seconds: int = 60
    sms_provider: str = "mock"
    sms_debug_echo: bool = False

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        populate_by_name = True


@lru_cache
def get_settings() -> Settings:
    return Settings()
