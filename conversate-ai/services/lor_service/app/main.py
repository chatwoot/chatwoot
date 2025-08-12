from fastapi import Depends, FastAPI, HTTPException
from typing import List

from . import schemas, runtime

app = FastAPI(
    title="LLM Orchestrator & Runtime (LOR/CRun) Service",
    description="The 'brain' of Conversate AI, orchestrating conversational flows.",
    version="0.1.0",
)

# --- Lifespan Management ---
@app.on_event("startup")
async def startup_event():
    # This initializes the HTTP and LLM clients used by the runtime
    runtime.initialize_clients()

# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "LOR/CRun Service", "status": "ok"}

@app.post("/orchestrate", response_model=schemas.OrchestrationResponse)
async def orchestrate_turn(request: schemas.OrchestrationRequest):
    """
    Orchestrates a single turn of a conversation by executing a bytecode flow.
    """
    try:
        # 1. Call the Conversation Runtime to execute the flow
        final_response, trace = await runtime.execute_flow(
            flow_id=request.flow_id,
            conversation_history=request.conversation_history,
            context=request.context
        )

        # 2. Format the response
        return schemas.OrchestrationResponse(
            conversation_id=request.conversation_id,
            response_message=final_response,
            decision_trace=trace
        )

    except ValueError as e:
        # Handle cases where the flow_id is not found
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        # Handle other potential errors during orchestration
        raise HTTPException(status_code=500, detail=f"An error occurred during orchestration: {e}")
