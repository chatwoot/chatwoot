import logging
import httpx
from openai import OpenAI
import os
import time
import json
from typing import List, Dict, Any

from . import schemas

# --- Globals ---
logger = logging.getLogger(__name__)
http_client: httpx.AsyncClient = None
llm_client: OpenAI = None

# --- Placeholder for our "Conversation Bytecode" flows ---
CONVERSATION_FLOWS = {
    "appointment_reschedule_v3": schemas.ConversationFlow(
        flow_id="appointment_reschedule_v3",
        steps=[
            schemas.BytecodeOp(id="retrieve_rules", op="RETRIEVE", params={"sources": ["kb://reschedule_policy"]}),
            schemas.BytecodeOp(id="generate_response", op="SAY", params={"prompt": "Based on the retrieved context, answer the user's question about rescheduling."}),
        ]
    )
}

# --- Client Initialization ---

def initialize_clients():
    global http_client, llm_client
    http_client = httpx.AsyncClient()
    # Ensure the API key is set in the environment for this to work
    llm_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
    logger.info("HTTP and LLM clients initialized.")

# --- Core Runtime Logic: The "Policy VM" ---

class ConversationRuntime:
    def __init__(self, flow_id: str, conversation_history: List[schemas.Turn], initial_context: Dict[str, Any]):
        if flow_id not in CONVERSATION_FLOWS:
            raise ValueError(f"Flow with id '{flow_id}' not found.")

        self.flow = CONVERSATION_FLOWS[flow_id]
        self.conversation_history = conversation_history
        self.context = initial_context
        self.trace = schemas.DecisionTrace(
            model_used="placeholder",
            think_budget_ms=0.0,
            final_response=""
        )

    async def execute(self):
        logger.info(f"Executing flow: {self.flow.flow_id}")
        for step in self.flow.steps:
            logger.info(f"Executing step: {step.id}, op: {step.op}")
            op_function = getattr(self, f"_execute_{step.op.lower()}", self._execute_unknown)
            await op_function(step)

        self.trace.final_response = self.context.get("last_response", "No response generated.")
        return self.context.get("last_response"), self.trace

    async def _execute_say(self, step: schemas.BytecodeOp):
        instruction = step.params.get("prompt", "Please respond.")

        # 1. Construct the messages payload for the LLM
        messages = []
        system_prompt = "You are a helpful assistant for the Conversate AI platform. Use the provided context to answer the user's question."
        if "retrieved_docs" in self.context and self.context["retrieved_docs"]:
            system_prompt += "\n\n### CONTEXT ###\n"
            for doc in self.context["retrieved_docs"]:
                system_prompt += f"- Document ID: {doc.get('id', 'N/A')}\nContent: {doc.get('content', '')}\n\n"

        messages.append({"role": "system", "content": system_prompt})

        # Add conversation history
        for turn in self.conversation_history:
            messages.append({"role": turn.role, "content": turn.content})

        # Add the final instruction
        messages.append({"role": "user", "content": instruction})

        logger.info(f"SAY op: Calling LLM with {len(messages)} messages.")

        try:
            # 2. Make the actual API call to OpenAI
            model_to_use = "gpt-4o" # As per CDNA-X, this could be decided by the orchestrator
            response = llm_client.chat.completions.create(
                model=model_to_use,
                messages=messages,
                temperature=0.7,
            )
            llm_response = response.choices[0].message.content
            self.context["last_response"] = llm_response
            self.trace.model_used = model_to_use
            logger.info("SAY op: Received response from LLM.")
        except Exception as e:
            logger.error(f"Error calling OpenAI API: {e}")
            self.context["last_response"] = "I'm sorry, but I'm having trouble connecting to my brain right now."


    async def _execute_retrieve(self, step: schemas.BytecodeOp):
        # This is the "Rule-Based Routing" for LOR v0. The rule is: if the flow
        # has a RETRIEVE op, we call the SOR service.

        # 1. Get the query from the last user turn
        last_user_turn = next((turn for turn in reversed(self.conversation_history) if turn.role == 'user'), None)
        if not last_user_turn:
            logger.warning("RETRIEVE op: No user turn found in history to use as a query.")
            return

        query = last_user_turn.content
        logger.info(f"RETRIEVE op: Calling SOR service with query: '{query}'")

        # 2. Call the SOR service
        sor_service_url = os.getenv("SOR_SERVICE_URL", "http://localhost:8003")
        try:
            response = await http_client.post(
                f"{sor_service_url}/search",
                json={"query": query, "top_k": 3},
                headers={"Authorization": f"Bearer {os.getenv('INTERNAL_API_TOKEN')}"}, # Assuming services are protected
                timeout=5.0
            )
            response.raise_for_status()
            evidence_bundle_data = response.json()
            evidence_bundle = schemas.EvidenceBundle.parse_obj(evidence_bundle_data)

            # 3. Update context and trace
            self.context["retrieved_docs"] = [c.dict() for c in evidence_bundle.citations]
            self.trace.retrieval = schemas.RetrievalTrace(
                docs=[c.dict() for c in evidence_bundle.citations],
                confidence=evidence_bundle.confidence
            )
            logger.info(f"RETRIEVE op: Received {len(evidence_bundle.citations)} citations with confidence {evidence_bundle.confidence:.2f}")

            # 4. Bandit Logging
            log_entry = {
                "timestamp": time.time(),
                "flow_id": self.flow.flow_id,
                "decision_type": "routing",
                "decision": "call_sor_service",
                "context": {"query": query},
                "outcome": {"confidence": evidence_bundle.confidence, "citations_found": len(evidence_bundle.citations)}
            }
            logger.info(f"BANDIT_LOG: {json.dumps(log_entry)}")

        except httpx.HTTPStatusError as e:
            logger.error(f"Error calling SOR service: {e.response.status_code} - {e.response.text}")
        except Exception as e:
            logger.error(f"An unexpected error occurred when calling SOR service: {e}")

    # Other opcode implementations remain the same...
    async def _execute_plan(self, step: schemas.BytecodeOp): pass
    async def _execute_assert(self, step: schemas.BytecodeOp): pass
    async def _execute_log_outcome(self, step: schemas.BytecodeOp): pass
    async def _execute_unknown(self, step: schemas.BytecodeOp): pass

# --- Public facing function for the API ---
async def execute_flow(flow_id: str, conversation_history: List[schemas.Turn], context: Dict[str, Any]):
    runtime = ConversationRuntime(flow_id, conversation_history, context)
    return await runtime.execute()
