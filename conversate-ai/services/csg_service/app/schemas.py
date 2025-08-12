from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime
import uuid

# --- Core Graph Node Models ---

class Actor(BaseModel):
    id: str = Field(default_factory=lambda: f"actor_{uuid.uuid4().hex}")
    type: str  # e.g., 'customer', 'agent', 'bot'
    crm_id: Optional[str] = None

class Intent(BaseModel):
    id: str = Field(default_factory=lambda: f"intent_{uuid.uuid4().hex}")
    name: str  # e.g., 'reschedule_appointment', 'query_pricing'
    confidence: float

class Entity(BaseModel):
    id: str = Field(default_factory=lambda: f"entity_{uuid.uuid4().hex}")
    type: str  # e.g., 'date', 'product_sku', 'location'
    value: Any
    text: str

class Policy(BaseModel):
    id: str = Field(default_factory=lambda: f"policy_{uuid.uuid4().hex}")
    name: str
    version: str

class Offer(BaseModel):
    id: str = Field(default_factory=lambda: f"offer_{uuid.uuid4().hex}")
    type: str # e.g., 'discount', 'free_trial'
    details: Dict[str, Any]

class Outcome(BaseModel):
    id: str = Field(default_factory=lambda: f"outcome_{uuid.uuid4().hex}")
    type: str  # e.g., 'conversion', 'csat_5', 'refund'
    value: Optional[float] = None

class Turn(BaseModel):
    id: str = Field(default_factory=lambda: f"turn_{uuid.uuid4().hex}")
    timestamp: datetime
    channel: str
    text: str
    actor_id: str
    episode_id: str
    meta: Dict[str, Any] = {}

class Episode(BaseModel):
    id: str = Field(default_factory=lambda: f"ep_{uuid.uuid4().hex}")
    start_time: datetime
    end_time: Optional[datetime] = None
    actor_ids: List[str]

class Context(BaseModel):
    id: str = Field(default_factory=lambda: f"context_{uuid.uuid4().hex}")
    type: str  # e.g., 'preference', 'constraint'
    key: str
    value: Any
    actor_id: str

# --- Event Ingestion Schema ---

class IngestEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: f"evt_{uuid.uuid4().hex}")
    timestamp: datetime
    channel: str
    actor_id: str
    org_id: str
    text: str
    attachments: List[Any] = []
    meta: Dict[str, Any] = {}
    labels: Dict[str, Any] = {} # For pre-computed labels like intent, sentiment
    outcome: Optional[Dict[str, Any]] = None
