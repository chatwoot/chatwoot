from fastapi import FastAPI, HTTPException
import logging
import httpx
import os

from . import schemas
from . import runtime

# --- App Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="LLM Orchestrator & Runtime (LOR/CRun) Service",
    description="The 'brain' of Conversate AI, orchestrating conversational flows.",
    version="0.1.0",
)

# --- Lifespan Management ---
@app.on_event("startup")
async def startup_event():
    logger.info("Starting LOR/CRun Service...")
    # In a real app, we might initialize clients here
    runtime.initialize_clients()
    logger.info("LOR/CRun Service started.")


# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "LOR/CRun Service", "status": "ok"}

@app.get("/health")
def health_check():
    # In a real app, this would check connectivity to other services and the LLM provider
    return {"status": "ok"}

@app.post("/orchestrate", response_model=schemas.OrchestrationResponse)
async def orchestrate_turn(request: schemas.OrchestrationRequest):
    """
    Orchestrates a single turn of a conversation.
    """
    logger.info(f"Orchestrating turn for conversation {request.conversation_id} with flow {request.flow_id}")

    try:
        # The runtime will execute the flow and return the final response and trace
        final_response, trace = await runtime.execute_flow(
            flow_id=request.flow_id,
            conversation_history=request.conversation_history,
            context=request.context
        )

        return schemas.OrchestrationResponse(
            conversation_id=request.conversation_id,
            response_message=final_response,
            decision_trace=trace
        )

    except Exception as e:
        logger.error(f"Error during orchestration: {e}")
        raise HTTPException(status_code=500, detail="An error occurred during orchestration.")
