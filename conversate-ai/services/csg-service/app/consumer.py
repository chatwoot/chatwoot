import logging
import threading
import time
from kafka import KafkaConsumer
import os
import json

# --- Globals ---
logger = logging.getLogger(__name__)
consumer_thread = None
stop_event = threading.Event()

# --- Kafka Consumer Logic ---

def start():
    """
    Starts the Kafka consumer in a separate thread.
    """
    global consumer_thread
    if consumer_thread is None or not consumer_thread.is_alive():
        stop_event.clear()
        consumer_thread = threading.Thread(target=consume_events)
        consumer_thread.daemon = True
        consumer_thread.start()
        logger.info("Kafka consumer thread started.")

def stop():
    """
    Stops the Kafka consumer thread.
    """
    logger.info("Stopping Kafka consumer thread...")
    stop_event.set()
    if consumer_thread and consumer_thread.is_alive():
        consumer_thread.join() # Wait for the thread to finish
    logger.info("Kafka consumer thread stopped.")


def consume_events():
    """
    The main loop for the Kafka consumer.
    """
    logger.info("Consumer loop started.")
    try:
        consumer = KafkaConsumer(
            os.getenv("KAFKA_TOPIC", "csg-ingest-events"),
            bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092"),
            group_id=os.getenv("KAFKA_GROUP_ID", "csg-service-group"),
            auto_offset_reset='earliest',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )
        logger.info(f"Subscribed to Kafka topic: {os.getenv('KAFKA_TOPIC', 'csg-ingest-events')}")
    except Exception as e:
        logger.error(f"Failed to connect to Kafka: {e}")
        return # Exit the thread if we can't connect

    while not stop_event.is_set():
        try:
            # Poll for messages with a timeout to allow for graceful shutdown
            messages = consumer.poll(timeout_ms=1000)
            if not messages:
                time.sleep(1) # Wait a bit if there are no messages
                continue

            for topic_partition, records in messages.items():
                for record in records:
                    process_kafka_message(record.value)

        except Exception as e:
            logger.error(f"Error in consumer loop: {e}")
            time.sleep(5) # Wait before retrying

    consumer.close()
    logger.info("Consumer loop finished.")


def process_kafka_message(event_data: dict):
    """
    Placeholder for processing a single message from Kafka.
    This is where we would parse the event and call the graph_db module.
    """
    # Here you would add your logic to process the message
    # For example, validating with Pydantic and then calling graph_db functions
    from . import schemas
    from . import main as app_main # to access process_single_event

    try:
        event = schemas.IngestEvent.parse_obj(event_data)
        logger.info(f"[Kafka] Processing event {event.event_id} for actor {event.actor_id}")
        # We can reuse the same processing logic as the API endpoint
        app_main.process_single_event(event)

    except Exception as e:
        logger.error(f"Failed to process Kafka message: {e}\nData: {event_data}")
