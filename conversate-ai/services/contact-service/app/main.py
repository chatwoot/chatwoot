from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session
from typing import List

from . import crud, models, schemas
from .database import SessionLocal, engine
from .security import get_current_user, UserInDB

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Contact Service",
    description="Manages contacts and customer data for Conversate AI.",
    version="0.1.0",
)

# --- Dependency ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "Contact Service", "status": "ok"}

@app.post("/contacts/", response_model=schemas.Contact)
def create_contact(
    contact: schemas.ContactCreate,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    # Ensure the contact is being created for the user's own account
    if contact.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to create a contact for this account")
    return crud.create_contact(db=db, contact=contact)

@app.get("/contacts/", response_model=List[schemas.Contact])
def read_contacts_for_account(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    contacts = crud.get_contacts_by_account(db, account_id=current_user.account_id, skip=skip, limit=limit)
    return contacts

@app.get("/contacts/{contact_id}", response_model=schemas.Contact)
def read_contact(
    contact_id: str,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    db_contact = crud.get_contact(db, contact_id=contact_id)
    if db_contact is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    if db_contact.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this contact")
    return db_contact

@app.put("/contacts/{contact_id}", response_model=schemas.Contact)
def update_contact(
    contact_id: str,
    contact: schemas.ContactBase,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    db_contact_to_update = crud.get_contact(db, contact_id=contact_id)
    if db_contact_to_update is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    if db_contact_to_update.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this contact")

    return crud.update_contact(db, contact_id=contact_id, contact_update=contact)

@app.delete("/contacts/{contact_id}", response_model=schemas.Contact)
def delete_contact(
    contact_id: str,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    db_contact_to_delete = crud.get_contact(db, contact_id=contact_id)
    if db_contact_to_delete is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    if db_contact_to_delete.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this contact")

    return crud.delete_contact(db, contact_id=contact_id)

@app.post("/contacts/{contact_id}/custom_attributes/", response_model=schemas.CustomAttribute)
def create_custom_attribute_for_contact(
    contact_id: str,
    attribute: schemas.CustomAttributeCreate,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    db_contact = crud.get_contact(db, contact_id=contact_id)
    if db_contact is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    if db_contact.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to modify this contact")
    return crud.add_custom_attribute_to_contact(db=db, contact_id=contact_id, attribute=attribute)

@app.delete("/custom_attributes/{attribute_id}", response_model=schemas.CustomAttribute)
def delete_custom_attribute(
    attribute_id: int,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    db_attribute = crud.delete_custom_attribute(db, attribute_id=attribute_id)
    if db_attribute is None:
        raise HTTPException(status_code=404, detail="Custom attribute not found")

    # Check ownership via the parent contact
    db_contact = crud.get_contact(db, contact_id=db_attribute.contact_id)
    if db_contact.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this attribute")

    return db_attribute
