from fastapi import Depends, HTTPException, Query
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from typing import Optional
import os

# --- Configuration ---
# This MUST be the same as in the Identity Service
SECRET_KEY = os.getenv("SECRET_KEY", "a_super_secret_key_for_dev")
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token") # Not used directly, but FastAPI needs it

# --- Pydantic model for the user data stored in the token ---
class UserInDB(BaseModel):
    email: str
    account_id: str

# --- Security Dependencies ---

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependency for REST endpoints.
    Decodes the JWT from the Authorization header.
    """
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        account_id: str = payload.get("acc")
        if email is None or account_id is None:
            raise credentials_exception

        user = UserInDB(email=email, account_id=account_id)

    except JWTError:
        raise credentials_exception

    if user is None:
        raise credentials_exception

    return user

async def get_current_user_from_query(token: Optional[str] = Query(None)):
    """
    Dependency for WebSocket endpoints.
    Decodes the JWT passed as a query parameter.
    """
    if token is None:
        raise HTTPException(status_code=401, detail="Missing token")

    # Reuse the same logic as the header-based dependency
    return await get_current_user(token=token)
