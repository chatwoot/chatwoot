from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from typing import Optional
import os

# --- Configuration ---
SECRET_KEY = os.getenv("SECRET_KEY", "a_super_secret_key_for_dev")
ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Pydantic model for the user data stored in the token ---
class UserInDB(BaseModel):
    email: str
    account_id: str

# --- Security Dependency ---

async def get_current_user(token: str = Depends(oauth2_scheme)):
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
