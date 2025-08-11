import uuid
import time
from datetime import datetime

# In a real test suite, we would import these from the actual service code.
# For this simulation, we are redefining them here to show the data contracts.
# This assumes the script is run from a context where it can see the service directories.
# from services.csg_service.app.schemas import IngestEvent
# from services.sor_service.app.schemas import SearchQuery, EvidenceBundle, Citation
# from services.lor_service.app.schemas import OrchestrationRequest, OrchestrationResponse, DecisionTrace, Turn

# --- Redefining Schemas for Simulation ---
# This is done to make the script self-contained for this demonstration.
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional

class IngestEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: f"evt_{uuid.uuid4().hex}")
    timestamp: datetime
    channel: str
    actor_id: str
    org_id: str
    text: str

class Citation(BaseModel):
    doc_id: str
    content: str
    score: float

class EvidenceBundle(BaseModel):
    citations: List[Citation]
    confidence: float

class Turn(BaseModel):
    role: str
    content: str

class DecisionTrace(BaseModel):
    model_used: str
    final_response: str

class OrchestrationRequest(BaseModel):
    conversation_id: str
    conversation_history: List[Turn]
    flow_id: str

# --- Mock Service Functions ---

def mock_csg_service_ingest(event: IngestEvent) -> dict:
    """Simulates the CSG service consuming an event."""
    print(f"[CSG] Ingesting event {event.event_id}...")
    # In a real service, this would write to a graph database.
    mock_graph_db = {
        "nodes": [
            {"id": event.actor_id, "type": "Actor"},
            {"id": f"turn_{event.event_id}", "type": "Turn", "text": event.text}
        ],
        "edges": [
            {"from": event.actor_id, "to": f"turn_{event.event_id}", "type": "PERFORMED"}
        ]
    }
    print("[CSG] Event processed and stored in graph.")
    return mock_graph_db

def mock_sor_service_search(query: str) -> EvidenceBundle:
    """Simulates the SOR service performing a search."""
    print(f"[SOR] Received search query: '{query}'")
    # In a real service, this would perform vector search.
    mock_citations = [
        Citation(doc_id="doc://faq/pricing", content="Our pricing is $10/month.", score=0.92),
        Citation(doc_id="doc://faq/features", content="We have many features.", score=0.85)
    ]
    bundle = EvidenceBundle(citations=mock_citations, confidence=0.88)
    print(f"[SOR] Returning evidence bundle with {len(bundle.citations)} citations.")
    return bundle

def mock_llm_call(prompt: str) -> str:
    """Simulates a call to an external LLM."""
    print(f"[LLM] Received prompt: '{prompt[:100]}...'")
    response = "Based on the context, the price is $10 per month."
    print(f"[LLM] Generated response: '{response}'")
    return response

def mock_lor_service_orchestrate(request: OrchestrationRequest) -> (str, DecisionTrace):
    """Simulates the LOR service orchestrating a turn."""
    print(f"\n[LOR] Orchestrating turn for conversation {request.conversation_id}...")

    # 1. Simulate RETRIEVE step from bytecode
    print("[LOR] Executing bytecode op: RETRIEVE")
    evidence = mock_sor_service_search(query=request.conversation_history[-1].content)

    # 2. Simulate SAY step from bytecode
    print("[LOR] Executing bytecode op: SAY")
    prompt = f"Context: {evidence.citations[0].content}\n\nUser asked: {request.conversation_history[-1].content}\n\nAnswer:"
    final_response = mock_llm_call(prompt)

    # 3. Create Decision Trace
    trace = DecisionTrace(model_used="gpt-5-mock", final_response=final_response)
    print("[LOR] Orchestration complete.")
    return final_response, trace

# --- Main Test Pipeline ---

def run_e2e_test():
    print("--- Starting End-to-End Pipeline Simulation ---")

    # --- Step 1: Ingest a new message into the system ---
    print("\n--- STAGE 1: INGESTION ---")
    start_time = time.time()

    ingest_event = IngestEvent(
        timestamp=datetime.now(),
        channel="webchat",
        actor_id="customer_123",
        org_id="org_abc",
        text="How much does it cost?"
    )
    mock_csg_service_ingest(ingest_event)

    ingestion_time_ms = (time.time() - start_time) * 1000
    print(f"SLO Check: Ingestion processed in {ingestion_time_ms:.2f} ms.")

    # --- Step 2: Orchestrate a response to the message ---
    print("\n--- STAGE 2: ORCHESTRATION & RESPONSE ---")
    start_time = time.time()

    orchestration_request = OrchestrationRequest(
        conversation_id="conv_xyz",
        conversation_history=[
            Turn(role="user", content="How much does it cost?")
        ],
        flow_id="sample_flow_v1"
    )

    response_message, decision_trace = mock_lor_service_orchestrate(orchestration_request)

    orchestration_time_ms = (time.time() - start_time) * 1000

    print("\n--- FINAL RESULT ---")
    print(f"Response to user: {response_message}")
    print(f"Decision Trace: {decision_trace.json(indent=2)}")

    # --- Step 3: Check SLOs/KPIs ---
    print("\n--- STAGE 3: SLO/KPI VALIDATION ---")
    print(f"SLO Check: Full orchestration time: {orchestration_time_ms:.2f} ms.")
    # In a real test, we would have assertions here.
    assert orchestration_time_ms < 2000, "SLO Violated: Orchestration took too long!"
    print("SLO Met: Orchestration time is within the 2000ms budget.")

    print("\n--- End-to-End Pipeline Simulation Complete ---")

if __name__ == "__main__":
    run_e2e_test()
