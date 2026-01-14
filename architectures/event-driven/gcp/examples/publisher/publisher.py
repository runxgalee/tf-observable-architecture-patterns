#!/usr/bin/env python3
"""
Pub/Sub Publisher Script for Event-Driven Architecture Testing

This script publishes messages to Google Cloud Pub/Sub for testing
the event-driven architecture deployment.

Usage:
    python publisher.py --project-id PROJECT_ID --topic TOPIC_NAME
    python publisher.py --project-id PROJECT_ID --topic TOPIC_NAME --message '{"key": "value"}'
    python publisher.py --project-id PROJECT_ID --topic TOPIC_NAME --count 10
    python publisher.py --project-id PROJECT_ID --topic TOPIC_NAME --file messages.json

Environment Variables:
    GOOGLE_CLOUD_PROJECT: Default project ID
    PUBSUB_TOPIC: Default topic name
"""

import argparse
import json
import logging
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from typing import Any

from google.cloud import pubsub_v1
from google.api_core import exceptions as google_exceptions

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


def create_sample_message(event_type: str = "test") -> dict[str, Any]:
    """Create a sample message with metadata."""
    return {
        "event_id": str(uuid.uuid4()),
        "event_type": event_type,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "data": {
            "message": "Hello from publisher!",
            "source": "test-publisher",
        },
    }


def publish_message(
    publisher: pubsub_v1.PublisherClient,
    topic_path: str,
    message: dict[str, Any],
    attributes: dict[str, str] | None = None,
) -> str:
    """
    Publish a single message to Pub/Sub.

    Args:
        publisher: Pub/Sub publisher client
        topic_path: Full topic path
        message: Message payload as dictionary
        attributes: Optional message attributes

    Returns:
        Published message ID
    """
    data = json.dumps(message).encode("utf-8")
    attrs = attributes or {}

    # Add default attributes
    attrs.setdefault("published_at", datetime.now(timezone.utc).isoformat())
    attrs.setdefault("publisher", "test-publisher")

    future = publisher.publish(topic_path, data, **attrs)
    message_id = future.result()

    return message_id


def publish_batch(
    publisher: pubsub_v1.PublisherClient,
    topic_path: str,
    count: int,
    delay: float = 0.1,
    event_type: str = "test",
) -> list[str]:
    """
    Publish multiple messages in batch.

    Args:
        publisher: Pub/Sub publisher client
        topic_path: Full topic path
        count: Number of messages to publish
        delay: Delay between messages in seconds
        event_type: Event type for messages

    Returns:
        List of published message IDs
    """
    message_ids = []

    for i in range(count):
        message = create_sample_message(event_type)
        message["data"]["sequence"] = i + 1
        message["data"]["total"] = count

        try:
            message_id = publish_message(publisher, topic_path, message)
            message_ids.append(message_id)
            logger.info(
                "Published message %d/%d: %s (event_id: %s)",
                i + 1,
                count,
                message_id,
                message["event_id"],
            )

            if delay > 0 and i < count - 1:
                time.sleep(delay)

        except google_exceptions.GoogleAPIError as e:
            logger.error("Failed to publish message %d: %s", i + 1, e)

    return message_ids


def publish_from_file(
    publisher: pubsub_v1.PublisherClient,
    topic_path: str,
    file_path: str,
) -> list[str]:
    """
    Publish messages from a JSON file.

    Args:
        publisher: Pub/Sub publisher client
        topic_path: Full topic path
        file_path: Path to JSON file containing messages

    Returns:
        List of published message IDs
    """
    with open(file_path, encoding="utf-8") as f:
        data = json.load(f)

    # Handle both single message and array of messages
    messages = data if isinstance(data, list) else [data]
    message_ids = []

    for i, message in enumerate(messages):
        try:
            # Add event_id if not present
            if "event_id" not in message:
                message["event_id"] = str(uuid.uuid4())
            if "timestamp" not in message:
                message["timestamp"] = datetime.now(timezone.utc).isoformat()

            message_id = publish_message(publisher, topic_path, message)
            message_ids.append(message_id)
            logger.info(
                "Published message %d/%d from file: %s",
                i + 1,
                len(messages),
                message_id,
            )

        except google_exceptions.GoogleAPIError as e:
            logger.error("Failed to publish message %d: %s", i + 1, e)

    return message_ids


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Publish messages to Google Cloud Pub/Sub",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Publish a single test message
  python publisher.py --project-id my-project --topic dev-events-events

  # Publish a custom JSON message
  python publisher.py -p my-project -t my-topic --message '{"event_type": "order", "data": {"id": 123}}'

  # Publish 10 messages with 0.5s delay
  python publisher.py -p my-project -t my-topic --count 10 --delay 0.5

  # Publish messages from a JSON file
  python publisher.py -p my-project -t my-topic --file messages.json

  # Simulate error scenario (for DLQ testing)
  python publisher.py -p my-project -t my-topic --event-type error --count 5
        """,
    )

    parser.add_argument(
        "-p",
        "--project-id",
        default=os.environ.get("GOOGLE_CLOUD_PROJECT"),
        help="GCP Project ID (default: GOOGLE_CLOUD_PROJECT env var)",
    )
    parser.add_argument(
        "-t",
        "--topic",
        default=os.environ.get("PUBSUB_TOPIC"),
        help="Pub/Sub topic name (default: PUBSUB_TOPIC env var)",
    )
    parser.add_argument(
        "-m",
        "--message",
        help="JSON message to publish (single message)",
    )
    parser.add_argument(
        "-c",
        "--count",
        type=int,
        default=1,
        help="Number of messages to publish (default: 1)",
    )
    parser.add_argument(
        "-d",
        "--delay",
        type=float,
        default=0.1,
        help="Delay between messages in seconds (default: 0.1)",
    )
    parser.add_argument(
        "-f",
        "--file",
        help="JSON file containing messages to publish",
    )
    parser.add_argument(
        "-e",
        "--event-type",
        default="test",
        help="Event type for generated messages (default: test)",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Validate required arguments
    if not args.project_id:
        logger.error(
            "Project ID is required. Use --project-id or set GOOGLE_CLOUD_PROJECT"
        )
        return 1

    if not args.topic:
        logger.error("Topic name is required. Use --topic or set PUBSUB_TOPIC")
        return 1

    # Initialize publisher
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(args.project_id, args.topic)

    logger.info("Publishing to topic: %s", topic_path)

    try:
        # Verify topic exists
        publisher.get_topic(request={"topic": topic_path})
    except google_exceptions.NotFound:
        logger.error("Topic not found: %s", topic_path)
        return 1
    except google_exceptions.PermissionDenied:
        logger.error("Permission denied for topic: %s", topic_path)
        return 1

    message_ids = []

    try:
        if args.file:
            # Publish from file
            message_ids = publish_from_file(publisher, topic_path, args.file)

        elif args.message:
            # Publish single custom message
            try:
                message = json.loads(args.message)
            except json.JSONDecodeError as e:
                logger.error("Invalid JSON message: %s", e)
                return 1

            message_id = publish_message(publisher, topic_path, message)
            message_ids.append(message_id)
            logger.info("Published message: %s", message_id)

        else:
            # Publish generated messages
            message_ids = publish_batch(
                publisher,
                topic_path,
                args.count,
                args.delay,
                args.event_type,
            )

        logger.info(
            "Successfully published %d message(s) to %s",
            len(message_ids),
            args.topic,
        )
        return 0

    except google_exceptions.GoogleAPIError as e:
        logger.error("Failed to publish messages: %s", e)
        return 1


if __name__ == "__main__":
    sys.exit(main())
