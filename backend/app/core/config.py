from functools import lru_cache
from typing import List

from pydantic import ConfigDict, Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Farm Platform Backend"
    api_v1_prefix: str = "/api/v1"
    secret_key: str = Field(..., alias="SECRET_KEY")
    access_token_expire_minutes: int = 30
    refresh_token_expire_minutes: int = 60 * 24 * 30
    database_url: str = Field(..., alias="DATABASE_URL")
    redis_url: str = Field(..., alias="REDIS_URL")
    api_host: str = Field(default="0.0.0.0", alias="API_HOST")
    api_port: int = Field(default=8000, alias="API_PORT")
    allowed_hosts: str = Field(default="")
    otp_expiration_minutes: int = 5
    otp_attempt_limit: int = 5
    otp_resend_interval_seconds: int = 60
    sms_provider: str = "dev"
    sms_debug_echo: bool = True
    payment_mock_mode: bool = Field(default=True, alias="PAYMENT_MOCK_MODE")

    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        populate_by_name=True
    )

    @property
    def allowed_hosts_list(self) -> List[str]:
        """Get allowed hosts as string list for CORS"""
        hosts = []
        if self.allowed_hosts:
            # Split comma-separated string into list
            hosts = [host.strip() for host in self.allowed_hosts.split(",") if host.strip()]
        # Always allow localhost for development
        if "http://localhost:3000" not in hosts:
            hosts.append("http://localhost:3000")
        if "http://localhost:5173" not in hosts:
            hosts.append("http://localhost:5173")
        return hosts


@lru_cache
def get_settings() -> Settings:
    return Settings()
