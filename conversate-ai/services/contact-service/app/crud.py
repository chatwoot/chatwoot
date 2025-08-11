from sqlalchemy.orm import Session

from . import models, schemas

# --- Contact CRUD ---

def get_contact(db: Session, contact_id: str):
    return db.query(models.Contact).filter(models.Contact.id == contact_id).first()

def get_contacts_by_account(db: Session, account_id: str, skip: int = 0, limit: int = 100):
    return db.query(models.Contact).filter(models.Contact.account_id == account_id).offset(skip).limit(limit).all()

def create_contact(db: Session, contact: schemas.ContactCreate):
    db_contact = models.Contact(**contact.dict())
    db.add(db_contact)
    db.commit()
    db.refresh(db_contact)
    return db_contact

def update_contact(db: Session, contact_id: str, contact_update: schemas.ContactBase):
    db_contact = get_contact(db, contact_id)
    if db_contact:
        update_data = contact_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_contact, key, value)
        db.commit()
        db.refresh(db_contact)
    return db_contact

def delete_contact(db: Session, contact_id: str):
    db_contact = get_contact(db, contact_id)
    if db_contact:
        db.delete(db_contact)
        db.commit()
    return db_contact

# --- Custom Attribute CRUD ---

def add_custom_attribute_to_contact(db: Session, contact_id: str, attribute: schemas.CustomAttributeCreate):
    db_attribute = models.CustomAttribute(**attribute.dict(), contact_id=contact_id)
    db.add(db_attribute)
    db.commit()
    db.refresh(db_attribute)
    return db_attribute

def delete_custom_attribute(db: Session, attribute_id: int):
    db_attribute = db.query(models.CustomAttribute).filter(models.CustomAttribute.id == attribute_id).first()
    if db_attribute:
        db.delete(db_attribute)
        db.commit()
    return db_attribute
