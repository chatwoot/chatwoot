"""Admin authentication: single-admin account, bcrypt passwords, signed-cookie sessions.

The panel has one administrator, created in the first-run setup wizard. Sessions are stateless
signed cookies (itsdangerous), keyed off the bootstrap ``APP_SECRET_KEY`` so no server-side
session store is needed.
"""
from __future__ import annotations

import bcrypt
from fastapi import Request
from fastapi.responses import RedirectResponse
from itsdangerous import BadSignature, URLSafeTimedSerializer
from sqlalchemy import func, select

from .config import settings
from .db import SessionLocal
from .models_db import AdminUser

COOKIE_NAME = "omni_session"
_MAX_AGE = 60 * 60 * 24 * 14  # 14 days


def _serializer() -> URLSafeTimedSerializer:
    return URLSafeTimedSerializer(settings.app_secret_key, salt="omni-admin-session")


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode(), password_hash.encode())
    except ValueError:
        return False


def issue_session(email: str) -> str:
    return _serializer().dumps({"email": email})


def read_session(request: Request) -> str | None:
    token = request.cookies.get(COOKIE_NAME)
    if not token:
        return None
    try:
        data = _serializer().loads(token, max_age=_MAX_AGE)
    except BadSignature:
        return None
    return data.get("email")


async def admin_exists() -> bool:
    async with SessionLocal() as session:
        count = await session.scalar(select(func.count()).select_from(AdminUser))
        return bool(count)


async def create_admin(email: str, password: str) -> None:
    async with SessionLocal() as session:
        session.add(AdminUser(email=email, password_hash=hash_password(password)))
        await session.commit()


async def authenticate(email: str, password: str) -> bool:
    async with SessionLocal() as session:
        user = await session.scalar(select(AdminUser).where(AdminUser.email == email))
    return bool(user and verify_password(password, user.password_hash))


def require_admin(request: Request) -> RedirectResponse | None:
    """Return a redirect to /admin/login when the request isn't authenticated, else None."""
    if read_session(request) is None:
        return RedirectResponse("/admin/login", status_code=303)
    return None
