import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from jose import jwt
from datetime import datetime, timedelta, timezone

from app.main import app, get_db
from app.database import Base
from app.security import get_current_user

# --- Test Database Setup ---

SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

# --- Mock Security ---

# Use the same secret key as the identity service for consistency
SECRET_KEY = "a_super_secret_key_for_dev"
ALGORITHM = "HS256"

def create_test_token(email: str, account_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=30)
    to_encode = {"sub": email, "acc": account_id, "exp": expire}
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- Test Client Setup ---

@pytest.fixture(scope="function")
def test_client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            db_session.close()

    # We don't need to override get_current_user because our mock token
    # is created with the same secret key, so the real dependency will work.
    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    del app.dependency_overrides[get_db]
