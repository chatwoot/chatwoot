import logging
import httpx
from openai import OpenAI
import os

from . import schemas

# --- Globals ---
logger = logging.getLogger(__name__)
http_client = None
llm_client = None

# --- Placeholder for our "Conversation Bytecode" flows ---
# In a real system, this would be loaded from a database or a config management system.
CONVERSATION_FLOWS = {
    "sample_flow_v1": schemas.ConversationFlow(
        flow_id="sample_flow_v1",
        steps=[
            schemas.BytecodeOp(id="step1", op="RETRIEVE", params={"query_prompt": "What is the user asking about?"}),
            schemas.BytecodeOp(id="step2", op="SAY", params={"prompt_template": "Based on the retrieved context, answer the user's question."}),
            schemas.BytecodeOp(id="step3", op="ASSERT", params={"constraint": "response_must_be_polite"}),
        ]
    )
}

# --- Client Initialization ---

def initialize_clients():
    global http_client, llm_client
    http_client = httpx.AsyncClient()
    llm_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    logger.info("HTTP and LLM clients initialized.")

# --- Core Runtime Logic ---

async def execute_flow(flow_id: str, conversation_history: list, context: dict):
    if flow_id not in CONVERSATION_FLOWS:
        raise ValueError(f"Flow with id '{flow_id}' not found.")

    flow = CONVERSATION_FLOWS[flow_id]
    current_context = context.copy()
    trace = {
        "model_used": "gpt-5-placeholder",
        "think_budget_ms": 500.0, # placeholder
        "constraints_checked": [],
        "retrieval": None
    }

    for step in flow.steps:
        if step.op == "RETRIEVE":
            await execute_retrieve_op(step, current_context, trace)
        elif step.op == "SAY":
            await execute_say_op(step, current_context, trace, conversation_history)
        elif step.op == "ASSERT":
            execute_assert_op(step, current_context, trace)
        else:
            logger.warning(f"Unknown opcode: {step.op}")

    final_response = current_context.get("last_response", "I'm sorry, I couldn't generate a response.")
    trace["final_response"] = final_response

    return final_response, schemas.DecisionTrace.parse_obj(trace)


async def execute_retrieve_op(step: schemas.BytecodeOp, current_context: dict, trace: dict):
    logger.info(f"Executing RETRIEVE op: {step.params}")
    sor_service_url = os.getenv("SOR_SERVICE_URL", "http://sor-service/search")

    # In a real scenario, we might use an LLM to generate the query for the SOR service
    query = step.params.get("query_prompt", "Default query")

    try:
        response = await http_client.post(sor_service_url, json={"query": query})
        response.raise_for_status()
        evidence_bundle = response.json()
        current_context["retrieved_docs"] = evidence_bundle["citations"]
        trace["retrieval"] = {
            "docs": evidence_bundle["citations"],
            "confidence": evidence_bundle["confidence"]
        }
        logger.info(f"Retrieved {len(evidence_bundle['citations'])} documents.")
    except httpx.RequestError as e:
        logger.error(f"Could not connect to SOR service: {e}")
        current_context["retrieved_docs"] = []


async def execute_say_op(step: schemas.BytecodeOp, current_context: dict, trace: dict, conversation_history: list):
    logger.info(f"Executing SAY op: {step.params}")

    # Construct a prompt for the LLM
    prompt = step.params.get("prompt_template", "Please respond.")
    if "retrieved_docs" in current_context:
        prompt += "\n\nUse the following context to answer:\n"
        for doc in current_context["retrieved_docs"]:
            prompt += f"- {doc['content']}\n"

    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        *conversation_history,
        {"role": "user", "content": prompt}
    ]

    try:
        # This is a mock call. In a real app, you would use the openai library correctly.
        # completion = llm_client.chat.completions.create(...)
        mock_response = f"This is a mock LLM response to the prompt: '{prompt[:50]}...'"
        current_context["last_response"] = mock_response
        logger.info(f"Generated LLM response.")
    except Exception as e:
        logger.error(f"Error calling LLM: {e}")
        current_context["last_response"] = "Error: Could not contact LLM."


def execute_assert_op(step: schemas.BytecodeOp, current_context: dict, trace: dict):
    constraint = step.params.get("constraint")
    logger.info(f"Executing ASSERT op: {constraint}")
    # Placeholder for constraint checking logic
    # e.g., check if response contains certain words, check sentiment, etc.
    trace["constraints_checked"].append(constraint)
