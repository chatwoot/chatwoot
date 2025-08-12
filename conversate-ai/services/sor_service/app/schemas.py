from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

# --- API Request Models ---

class SearchQuery(BaseModel):
    query: str
    top_k: int = 5
    context: Dict[str, Any] = {} # e.g., actor_id, org_id, conversation_history

# --- API Response Models ---

class Citation(BaseModel):
    doc_id: str # e.g., 'policy://reschedule#3'
    span: Optional[str] = None # e.g., 'L11-L28'
    content: str
    score: float

class Verification(BaseModel):
    check_name: str # e.g., 'hours_match', 'fee_rule_applied'
    status: bool
    details: str

class EvidenceBundle(BaseModel):
    citations: List[Citation]
    confidence: float
    verifications: List[Verification]
    processing_time_ms: float
