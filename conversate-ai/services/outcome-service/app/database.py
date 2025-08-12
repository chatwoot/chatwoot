from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# --- Database Configuration ---

DATABASE_URL = os.getenv("OM_DATABASE_URL", "postgresql://user:password@localhost/om_db")

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# --- Dependency for getting a DB session ---

def get_db():
    """
    FastAPI dependency that provides a SQLAlchemy database session.
    It ensures the session is always closed after the request.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
