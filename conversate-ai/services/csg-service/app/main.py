from fastapi import FastAPI, BackgroundTasks
from typing import List
import logging

from . import schemas
from . import graph_db
from . import consumer

# --- App Configuration ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Conversational State Graph (CSG) Service",
    description="Manages the temporal knowledge graph for all conversations.",
    version="0.1.0",
)

# --- Lifespan Management (for DB connections, Kafka consumer) ---
@app.on_event("startup")
async def startup_event():
    logger.info("Starting CSG Service...")
    graph_db.connect()
    # In a real app, the consumer would be started in a separate process
    # or managed more robustly (e.g., with a k8s sidecar or a dedicated consumer process).
    # For now, we'll just log that it's "started".
    consumer.start()
    logger.info("CSG Service started.")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down CSG Service...")
    graph_db.close()
    consumer.stop()
    logger.info("CSG Service shut down.")


# --- API Endpoints ---

@app.get("/")
def read_root():
    return {"service": "CSG Service", "status": "ok"}

@app.get("/health")
def health_check():
    return {"status": "ok", "db_connection": graph_db.get_status()}

@app.post("/ingest", status_code=202)
async def ingest_events(events: List[schemas.IngestEvent], background_tasks: BackgroundTasks):
    """
    Accepts a list of events to be processed and added to the graph.
    This is a secondary ingestion method; the primary is the Kafka consumer.
    """
    logger.info(f"Received {len(events)} events for ingestion via API.")
    # In a real application, we would push this to a queue (like Kafka)
    # For now, we'll process it in the background.
    for event in events:
        background_tasks.add_task(process_single_event, event)

    return {"message": "Events accepted for processing."}

def process_single_event(event: schemas.IngestEvent):
    """
    Placeholder function for processing a single event and adding it to the graph.
    """
    logger.info(f"Processing event {event.event_id} for actor {event.actor_id}")
    # 1. Create/get Actor node
    # 2. Create Turn node
    # 3. Create Episode node if it doesn't exist
    # 4. Link nodes together (Actor -> Turn, Turn -> Episode)
    # 5. Process labels to create Intent/Entity nodes and link them to the Turn
    # 6. Process outcome and link it
    pass
