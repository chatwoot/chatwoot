from fastapi import Depends, FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import List
import json
import httpx
import os

from . import crud, models, schemas
from .database import SessionLocal, engine, Base
from .connection_manager import manager
from .security import get_current_user, get_current_user_from_query, UserInDB

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Conversation Service",
    description="Manages conversations and real-time messaging for Conversate AI.",
    version="0.1.0",
)

http_client: httpx.AsyncClient = None

# --- Lifespan Management ---
@app.on_event("startup")
async def startup_event():
    global http_client
    http_client = httpx.AsyncClient()

@app.on_event("shutdown")
async def shutdown_event():
    await http_client.aclose()


# --- Dependency ---
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- WebSocket Endpoint ---

@app.websocket("/ws/{conversation_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    conversation_id: str,
    current_user: UserInDB = Depends(get_current_user_from_query),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation or conversation.account_id != current_user.account_id:
        await websocket.close(code=4003)
        return

    await manager.connect(websocket, conversation_id)
    try:
        while True:
            data = await websocket.receive_text()

            # 1. Save the incoming message from the user/contact
            message_data = json.loads(data)
            incoming_message_schema = schemas.MessageCreate(
                content=message_data.get("content"),
                sender_id=current_user.email,
                sender_type="user" # Assuming the person in the dashboard is a 'user'
            )
            db_incoming_message = crud.create_message_in_conversation(db=db, message=incoming_message_schema, conversation_id=conversation_id)
            await manager.broadcast(schemas.Message.from_orm(db_incoming_message).json(), conversation_id)

            # 2. Get history and call the LOR service for an AI response
            history = crud.get_messages_for_conversation(db, conversation_id, limit=10)
            lor_request = {
                "conversation_id": conversation_id,
                "conversation_history": [{"role": msg.sender_type, "content": msg.content} for msg in history],
                "context": {"episode_id": f"ep_{conversation_id}"},
                "flow_id": "appointment_reschedule_v3" # Using the placeholder flow
            }

            lor_service_url = os.getenv("LOR_SERVICE_URL", "http://lor-service/orchestrate")
            try:
                response = await http_client.post(lor_service_url, json=lor_request, timeout=10.0)
                response.raise_for_status()
                lor_response_data = response.json()
                ai_message_content = lor_response_data.get("response_message")

                # 3. Save the AI's response
                ai_message_schema = schemas.MessageCreate(
                    content=ai_message_content,
                    sender_id="ai_assistant_1", # Placeholder ID for the assistant
                    sender_type="assistant"
                )
                db_ai_message = crud.create_message_in_conversation(db=db, message=ai_message_schema, conversation_id=conversation_id)

                # 4. Broadcast the AI's response
                await manager.broadcast(schemas.Message.from_orm(db_ai_message).json(), conversation_id)

            except httpx.RequestError as e:
                error_message = f"Could not connect to LOR service: {e}"
                await manager.broadcast_json({"error": error_message}, conversation_id)
            except httpx.HTTPStatusError as e:
                error_message = f"Error from LOR service: {e.response.status_code} - {e.response.text}"
                await manager.broadcast_json({"error": error_message}, conversation_id)


    except WebSocketDisconnect:
        manager.disconnect(websocket, conversation_id)
        await manager.broadcast_json({"message": f"Client {current_user.email} left the chat"}, conversation_id)

# --- REST API Endpoints (remain unchanged) ---
# ... (omitted for brevity, but they are still here)
@app.get("/")
def read_root():
    return {"service": "Conversation Service", "status": "ok"}
# ... etc ...
