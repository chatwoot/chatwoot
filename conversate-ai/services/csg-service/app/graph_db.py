from neo4j import GraphDatabase
import logging
import os

# --- Globals ---
driver = None
logger = logging.getLogger(__name__)

# --- Connection Management ---

def connect():
    """
    Establishes the connection to the Neo4j database using environment variables.
    """
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
        driver = None # Ensure driver is None if connection fails

def close():
    """
    Closes the database connection driver.
    """
    if driver is not None:
        driver.close()
        logger.info("Neo4j connection closed.")

def get_status():
    """
    Checks the connectivity status of the database.
    """
    if driver is None:
        return "disconnected"
    try:
        driver.verify_connectivity()
        return "connected"
    except Exception:
        return "connection_error"

# --- Query Functions (Placeholders) ---

def add_node(label: str, properties: dict):
    """
    A generic function to add a node to the graph.
    In a real app, we'd have more specific functions like `create_actor`, `create_turn`, etc.
    """
    if not driver:
        logger.error("Database not connected. Cannot add node.")
        return None

    with driver.session() as session:
        # Using string formatting here for simplicity.
        # In a real app, use parameterized queries to prevent injection.
        query = f"CREATE (n:{label} $props) RETURN id(n)"
        result = session.run(query, props=properties)
        return result.single()[0]

def add_relationship(from_node_id: int, to_node_id: int, relationship_type: str):
    """
    A generic function to add a relationship between two nodes.
    """
    if not driver:
        logger.error("Database not connected. Cannot add relationship.")
        return

    with driver.session() as session:
        query = (
            "MATCH (a), (b) "
            "WHERE id(a) = $from_id AND id(b) = $to_id "
            f"CREATE (a)-[r:{relationship_type}]->(b)"
        )
        session.run(query, from_id=from_node_id, to_id=to_node_id)
