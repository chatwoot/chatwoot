import sys
import os
import uuid
import time
from datetime import datetime
import json
from pathlib import Path

# --- BOOTSTRAP SCRIPT TO FIX ENVIRONMENT ---
# Add the project root to the python path to allow for absolute imports
# The test script is in /app/conversate-ai/tests, so the project root is one level up.
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# --- END BOOTSTRAP ---


from services.csg_service.app.schemas import IngestEvent
from services.sor_service.app.schemas import SearchQuery, EvidenceBundle, Citation, Verification
from services.lor_service.app.schemas import OrchestrationRequest, OrchestrationResponse, DecisionTrace, Turn, RetrievalTrace

# --- Mock Service Functions ---

mock_event_bus = {
    "csg_events": [],
    "sor_requests": [],
    "lor_requests": [],
}

def mock_csg_service_ingest(event: IngestEvent):
    print(f"[CSG] Ingesting event {event.event_id}...")
    mock_event_bus["csg_events"].append(event)
    print(f"[CSG] Event processed. Total events in graph: {len(mock_event_bus['csg_events'])}")

def mock_sor_service_search(query: SearchQuery) -> EvidenceBundle:
    print(f"[SOR] Received search query: '{query.query}'")
    mock_event_bus["sor_requests"].append(query)

    should_retrieve = any(keyword in query.query.lower() for keyword in ["how", "what", "price"])

    if not should_retrieve:
        return EvidenceBundle(
            citations=[],
            confidence=0.9,
            verifications=[Verification(check_name="retrieval_trigger", status=False, details="Query does not require external knowledge.")],
            processing_time_ms=15.0
        )

    citations = [
        Citation(doc_id="doc://faq/pricing", content="Our pricing is $10/month.", score=0.92),
        Citation(doc_id="doc://faq/features", content="We have many features.", score=0.85)
    ]
    bundle = EvidenceBundle(
        citations=citations,
        confidence=0.88,
        verifications=[
            Verification(check_name="retrieval_trigger", status=True, details="Retrieval was triggered."),
            Verification(check_name="relevance_critique", status=True, details="Kept 2 of 2 chunks.")
        ],
        processing_time_ms=120.0
    )
    print(f"[SOR] Returning evidence bundle with {len(bundle.citations)} citations.")
    return bundle

def mock_llm_call(prompt: str) -> str:
    print(f"[LLM] Received prompt: '{prompt[:100]}...'")
    response = "Based on our documentation, the price is $10 per month. Let me know if you need anything else!"
    print(f"[LLM] Generated response: '{response}'")
    return response

def mock_lor_service_orchestrate(request: OrchestrationRequest) -> OrchestrationResponse:
    print(f"\n[LOR] Orchestrating turn for conversation {request.conversation_id}...")
    mock_event_bus["lor_requests"].append(request)

    final_response = "An error occurred."
    trace = None

    print("[LOR] Executing bytecode op: RETRIEVE")
    search_query = SearchQuery(query=request.conversation_history[-1].content, top_k=3)
    evidence = mock_sor_service_search(search_query)

    print("[LOR] Executing bytecode op: SAY")
    context_str = "\n".join([f"- {c.content}" for c in evidence.citations])
    prompt = f"Context: {context_str}\n\nUser asked: {request.conversation_history[-1].content}\n\nAnswer:"
    final_response = mock_llm_call(prompt)

    retrieval_trace = RetrievalTrace(docs=[c.dict() for c in evidence.citations], confidence=evidence.confidence)
    trace = DecisionTrace(
        model_used="gpt-5-mock",
        think_budget_ms=150.0,
        retrieval=retrieval_trace,
        final_response=final_response
    )
    print("[LOR] Orchestration complete.")

    return OrchestrationResponse(
        conversation_id=request.conversation_id,
        response_message=final_response,
        decision_trace=trace
    )

# --- Main Test Pipeline ---

def run_e2e_test():
    print("--- Starting End-to-End CDNA-X v0 Pipeline Simulation ---")
    mock_event_bus.clear()

    print("\n--- STAGE 1: INGESTION ---")

    user_message = "How much does it cost?"
    ingest_event = IngestEvent(
        timestamp=datetime.now(),
        channel="webchat",
        actor_id="customer_123",
        org_id="org_abc",
        text=user_message,
        labels={
            "intent": {"name": "query_pricing", "confidence": 0.98},
            "entities": [{"type": "product", "value": "default", "text": "it"}]
        }
    )
    mock_csg_service_ingest(ingest_event)

    assert len(mock_event_bus["csg_events"]) == 1
    assert mock_event_bus["csg_events"][0].text == user_message
    print("✅ Ingestion verification successful.")

    print("\n--- STAGE 2: ORCHESTRATION & RESPONSE ---")

    orchestration_request = OrchestrationRequest(
        conversation_id="conv_xyz",
        conversation_history=[Turn(role="user", content=user_message)],
        flow_id="appointment_reschedule_v3"
    )

    orchestration_response = mock_lor_service_orchestrate(orchestration_request)

    assert len(mock_event_bus["lor_requests"]) == 1
    assert len(mock_event_bus["sor_requests"]) == 1
    assert mock_event_bus["sor_requests"][0].query == user_message

    print("\n--- FINAL RESULT ---")
    print(f"Response to user: {orchestration_response.response_message}")
    print(f"Decision Trace: {orchestration_response.decision_trace.json(indent=2)}")

    print("\n--- STAGE 3: OUTPUT VALIDATION ---")

    final_trace = orchestration_response.decision_trace
    assert "Based on our documentation" in orchestration_response.response_message
    assert final_trace.retrieval is not None
    assert final_trace.retrieval.confidence > 0.8
    assert len(final_trace.retrieval.docs) == 2
    assert final_trace.retrieval.docs[0]["doc_id"] == "doc://faq/pricing"

    print("✅ Output validation successful. The trace contains the correct retrieval info.")
    print("\n--- End-to-End Pipeline Simulation Complete ---")


if __name__ == "__main__":
    run_e2e_test()
