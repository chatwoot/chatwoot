from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime

# --- Custom Attribute Schemas ---

class CustomAttributeBase(BaseModel):
    name: str
    value: str

class CustomAttributeCreate(CustomAttributeBase):
    pass

class CustomAttribute(CustomAttributeBase):
    id: int

    class Config:
        orm_mode = True

# --- Contact Schemas ---

class ContactBase(BaseModel):
    email: Optional[EmailStr] = None
    phone_number: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    additional_attributes: Optional[Dict[str, Any]] = None

class ContactCreate(ContactBase):
    account_id: str

class Contact(ContactBase):
    id: str
    account_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    custom_attributes: List[CustomAttribute] = []

    class Config:
        orm_mode = True
