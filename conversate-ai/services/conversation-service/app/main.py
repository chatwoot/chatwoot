from fastapi import Depends, FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from typing import List
import json

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
    # Check if the user has access to this conversation
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation or conversation.account_id != current_user.account_id:
        await websocket.close(code=4003) # Custom code for permission denied
        return

    await manager.connect(websocket, conversation_id)
    try:
        while True:
            data = await websocket.receive_text()

            # Parse the incoming message and add sender info
            message_data = json.loads(data)
            message_schema = schemas.MessageCreate(
                content=message_data.get("content"),
                sender_id=current_user.email, # Or a user ID if we had one in the token
                sender_type="user"
            )

            # Save the message to the database
            db_message = crud.create_message_in_conversation(db=db, message=message_schema, conversation_id=conversation_id)

            # Broadcast the new message to all clients in the room
            broadcast_message = schemas.Message.from_orm(db_message).json()
            await manager.broadcast(broadcast_message, conversation_id)

    except WebSocketDisconnect:
        manager.disconnect(websocket, conversation_id)
        await manager.broadcast_json({"message": f"Client {current_user.email} left the chat"}, conversation_id)

# --- REST API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "Conversation Service", "status": "ok"}

@app.post("/conversations/", response_model=schemas.Conversation)
def create_conversation(
    conversation: schemas.ConversationCreate,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    if conversation.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to create conversations for this account")
    return crud.create_conversation(db=db, conversation=conversation)

@app.get("/conversations/", response_model=List[schemas.Conversation])
def read_conversations(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    return crud.get_conversations_by_account(db, account_id=current_user.account_id, skip=skip, limit=limit)

@app.get("/conversations/{conversation_id}/messages", response_model=List[schemas.Message])
def read_messages(
    conversation_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: UserInDB = Depends(get_current_user)
):
    conversation = crud.get_conversation(db, conversation_id)
    if not conversation or conversation.account_id != current_user.account_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this conversation")
    return crud.get_messages_for_conversation(db, conversation_id=conversation_id, skip=skip, limit=limit)
