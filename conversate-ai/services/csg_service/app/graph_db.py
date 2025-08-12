from neo4j import GraphDatabase, ManagedTransaction
import logging
import os
from . import schemas

# --- Globals ---
driver = None
logger = logging.getLogger(__name__)

# --- Connection Management ---

def connect():
    global driver
    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    user = os.getenv("NEO4J_USER", "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password")
    try:
        driver = GraphDatabase.driver(uri, auth=(user, password))
        driver.verify_connectivity()
        logger.info("Successfully connected to Neo4j database.")
    except Exception as e:
        logger.error(f"Failed to connect to Neo4j: {e}")
        driver = None

def close():
    if driver is not None:
        driver.close()
        logger.info("Neo4j connection closed.")

def get_status():
    if driver is None: return "disconnected"
    try:
        driver.verify_connectivity()
        return "connected"
    except Exception:
        return "connection_error"

# --- Transactional Cypher Functions ---

def _find_or_create_actor(tx: ManagedTransaction, actor_id: str):
    # Using MERGE ensures that we don't create duplicate nodes for the same actor
    query = (
        "MERGE (a:Actor {actor_id: $actor_id}) "
        "RETURN a"
    )
    result = tx.run(query, actor_id=actor_id)
    return result.single()[0]

def _find_or_create_episode(tx: ManagedTransaction, event: schemas.IngestEvent):
    # For simplicity, we'll use a placeholder episode_id. In a real app, this would be managed.
    episode_id = f"ep_{event.org_id}_{event.actor_id}"
    query = (
        "MERGE (e:Episode {episode_id: $episode_id}) "
        "ON CREATE SET e.start_time = $timestamp "
        "RETURN e"
    )
    result = tx.run(query, episode_id=episode_id, timestamp=event.timestamp)
    return result.single()[0]

def _create_turn_and_link_to_episode(tx: ManagedTransaction, event: schemas.IngestEvent, episode_node):
    turn_id = f"turn_{event.event_id}"
    query = (
        "MATCH (e:Episode) WHERE id(e) = $episode_id "
        "CREATE (t:Turn {turn_id: $turn_id, text: $text, timestamp: $timestamp, channel: $channel}) "
        "CREATE (e)-[:HAS_TURN]->(t) "
        "RETURN t"
    )
    result = tx.run(query, episode_id=episode_node.id, turn_id=turn_id, text=event.text, timestamp=event.timestamp, channel=event.channel)
    return result.single()[0]

def _link_actor_to_turn(tx: ManagedTransaction, actor_node, turn_node):
    query = (
        "MATCH (a:Actor), (t:Turn) "
        "WHERE id(a) = $actor_id AND id(t) = $turn_id "
        "CREATE (a)-[:PERFORMED]->(t)"
    )
    tx.run(query, actor_id=actor_node.id, turn_id=turn_node.id)

# --- Main Public Function ---

def process_event(event: schemas.IngestEvent):
    """
    Processes a single ingest event and writes it to the graph database in a single transaction.
    """
    if not driver:
        logger.error("Database not connected. Cannot process event.")
        return

    with driver.session() as session:
        session.write_transaction(_create_graph_nodes_for_event, event)
    logger.info(f"Successfully processed event {event.event_id} into the graph.")

def _create_intent_and_link_to_turn(tx: ManagedTransaction, turn_node, intent_data: dict):
    intent = schemas.Intent.parse_obj(intent_data)
    query = (
        "MATCH (t:Turn) WHERE id(t) = $turn_id "
        "CREATE (i:Intent {intent_id: $intent_id, name: $name, confidence: $confidence}) "
        "CREATE (t)-[:HAS_INTENT]->(i)"
    )
    tx.run(query, turn_id=turn_node.id, intent_id=intent.id, name=intent.name, confidence=intent.confidence)

def _create_entity_and_link_to_turn(tx: ManagedTransaction, turn_node, entity_data: dict):
    entity = schemas.Entity.parse_obj(entity_data)
    query = (
        "MATCH (t:Turn) WHERE id(t) = $turn_id "
        "CREATE (e:Entity {entity_id: $entity_id, type: $type, value: $value, text: $text}) "
        "CREATE (t)-[:HAS_ENTITY]->(e)"
    )
    tx.run(query, turn_id=turn_node.id, entity_id=entity.id, type=entity.type, value=str(entity.value), text=entity.text)

def _create_outcome_and_link_to_turn(tx: ManagedTransaction, turn_node, outcome_data: dict):
    outcome = schemas.Outcome.parse_obj(outcome_data)
    query = (
        "MATCH (t:Turn) WHERE id(t) = $turn_id "
        "CREATE (o:Outcome {outcome_id: $outcome_id, type: $type, value: $value}) "
        "CREATE (t)-[:LEAD_TO_OUTCOME]->(o)"
    )
    tx.run(query, turn_id=turn_node.id, outcome_id=outcome.id, type=outcome.type, value=outcome.value)


def _create_graph_nodes_for_event(tx: ManagedTransaction, event: schemas.IngestEvent):
    # 1. Find or create the Actor node
    actor_node = _find_or_create_actor(tx, event.actor_id)

    # 2. Find or create the Episode node
    episode_node = _find_or_create_episode(tx, event)

    # 3. Create the Turn node and link it to the Episode
    turn_node = _create_turn_and_link_to_episode(tx, event, episode_node)

    # 4. Link the Actor to the Turn
    _link_actor_to_turn(tx, actor_node, turn_node)

    # 5. Process labels (Intents and Entities)
    if event.labels:
        if "intent" in event.labels and isinstance(event.labels["intent"], dict):
            _create_intent_and_link_to_turn(tx, turn_node, event.labels["intent"])

        if "entities" in event.labels and isinstance(event.labels["entities"], list):
            for entity_data in event.labels["entities"]:
                if isinstance(entity_data, dict):
                    _create_entity_and_link_to_turn(tx, turn_node, entity_data)

    # 6. Process outcome
    if event.outcome and isinstance(event.outcome, dict):
        _create_outcome_and_link_to_turn(tx, turn_node, event.outcome)

    return True

def get_episode_history(episode_id: str):
    """
    Retrieves all turns for a given episode, ordered by timestamp.
    """
    if not driver:
        logger.error("Database not connected. Cannot get episode history.")
        return []

    with driver.session() as session:
        result = session.read_transaction(_get_turns_for_episode, episode_id)
    return result

def _get_turns_for_episode(tx: ManagedTransaction, episode_id: str):
    query = (
        "MATCH (e:Episode {episode_id: $episode_id})-[:HAS_TURN]->(t:Turn) "
        "RETURN t "
        "ORDER BY t.timestamp ASC"
    )
    result = tx.run(query, episode_id=episode_id)
    # Convert the Neo4j nodes to dictionaries for Pydantic validation
    return [record["t"]._properties for record in result]
