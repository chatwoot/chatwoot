from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

# --- Conversation Bytecode (CB) Schemas ---

class BytecodeOp(BaseModel):
    id: str
    op: str # e.g., 'SAY', 'RETRIEVE', 'PLAN', 'ASSERT'
    params: Dict[str, Any] = {}

class ConversationFlow(BaseModel):
    flow_id: str
    steps: List[BytecodeOp]

# --- Decision Trace Schema ---

class RetrievalTrace(BaseModel):
    docs: List[Dict[str, Any]]
    confidence: float

class DecisionTrace(BaseModel):
    model_used: str
    think_budget_ms: float
    retrieval: Optional[RetrievalTrace] = None
    constraints_checked: List[str] = []
    chosen_template: Optional[str] = None
    final_response: str

# --- API Request/Response Schemas ---

class Turn(BaseModel):
    role: str # 'user' or 'assistant'
    content: str

class OrchestrationRequest(BaseModel):
    conversation_id: str
    conversation_history: List[Turn]
    context: Dict[str, Any] = {}
    flow_id: str # The ID of the ConversationFlow to execute

class OrchestrationResponse(BaseModel):
    conversation_id: str
    response_message: str
    decision_trace: DecisionTrace
