import logging
import threading
import time
from kafka import KafkaConsumer
import os
import json

from . import schemas, graph_db

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
        consumer_thread.join()
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
        return

    while not stop_event.is_set():
        try:
            messages = consumer.poll(timeout_ms=1000)
            if not messages:
                time.sleep(1)
                continue

            for topic_partition, records in messages.items():
                for record in records:
                    process_kafka_message(record.value)

        except Exception as e:
            logger.error(f"Error in consumer loop: {e}")
            time.sleep(5)

    consumer.close()
    logger.info("Consumer loop finished.")

def process_kafka_message(event_data: dict):
    """
    Parses a message from Kafka, validates it, and passes it to the graph_db module.
    """
    try:
        # 1. Validate the incoming data against our Pydantic schema
        event = schemas.IngestEvent.parse_obj(event_data)
        logger.info(f"[Kafka] Processing event {event.event_id} for actor {event.actor_id}")

        # 2. Pass the validated event to our graph database logic
        graph_db.process_event(event)

    except Exception as e:
        # In a real system, we would move this message to a dead-letter queue (DLQ)
        # for later inspection instead of just logging the error.
        logger.error(f"Failed to process Kafka message: {e}\nData: {event_data}")
