"""
This module provides a service for interacting with the Instagram Messaging API. It allows sending both text and audio messages to users, as well as retrieving message conversations involving a specific username.
"""

from typing import Any, List

import requests
from injector import inject

from app.config import settings
from app.domain.abstract_classes.services.messaging_service import (
    MessagingPlatformService,
)
from app.domain.entities.chat_entities import (
    ChatContextEntity,
    ChatMessageEntity,
    ImageToSendEntity,
)
from app.domain.entities.store_entities import StoreEntity
from app.domain.entities.user_entities import UserMetadataEntity
from app.domain.enums.chat_enums import Channel
from app.domain.enums.messaging_enums import TagType


class InstagramService(MessagingPlatformService):
    """
    This module defines the `InstagramService` class, which provides various methods to interact with Instagram-related functionalities.
    """

    @inject
    def __init__(self) -> None:
        pass

    def get_chat_link(self, chat_context: ChatContextEntity) -> str:
        """
        Retrieves the link to a chat based on the provided chat context.
        """
        raise NotImplementedError("get_chat_link function not implemented yet.")

    async def get_latest_chats_for_recovery(
        self, store_entity: StoreEntity, channel: Channel
    ) -> List[str]:
        """
        Retrieves the latest chats for recovery from a given store and channel.
        """
        raise NotImplementedError(
            "get_latest_chats_for_recovery function not implemented yet."
        )

    async def fetch_message_media(
        self,
        chat_message_entity: ChatMessageEntity,
        chat_context_entity: ChatContextEntity,
    ) -> ChatMessageEntity:
        """
        Fetches media contents from the given chat message.
        """
        raise NotImplementedError(
            "fetch_message_media function not implemented yet."
        )

    async def tag_user(
        self, chat_context_entity: ChatContextEntity, tag: TagType
    ) -> None:
        """
        Tags a user in a chat context with a specified tag.
        """
        raise NotImplementedError("tag_user function not implemented yet.")

    async def get_user_metadata(
        self, chat_context_entity: ChatContextEntity
    ) -> UserMetadataEntity:
        """
        An asynchronous method to fetch metadata of a user based on the provided chat
        context.
        """
        raise NotImplementedError(
            "get_user_metadata function not implemented yet."
        )

    async def send_image_message(
        self, chat_context_entity: ChatContextEntity, image: ImageToSendEntity
    ) -> dict:
        """
        Asynchronously sends an image message to a chat context.
        """
        raise NotImplementedError(
            "send_image_message function not implemented yet."
        )

    async def send_images_catalog(
        self,
        chat_context_entity: ChatContextEntity,
        images_catalog: List[ImageToSendEntity],
    ) -> Any:
        """
        Sends a catalog of images to the chat context provided.
        """
        raise NotImplementedError(
            "send_images_catalog function not implemented yet."
        )

    def _send_text_message(
        self, chat_context_entity: ChatContextEntity, message: str
    ) -> None:
        """Send a text message to a recipient."""
        url = f"https://graph.facebook.com/v20.0/me/messages?access_token={settings.IG_PAGE_TOKEN}"
        recipient_id = chat_context_entity.chat_session.external_id
        payload = {
            "recipient": {"id": recipient_id},
            "message": {"text": message},
        }

        response = requests.post(
            url, json=payload, timeout=settings.REQUEST_TIMEOUT_IN_SECONDS
        )

        if response.status_code == 200:
            print("Message sent successfully!")
        else:
            print(f"Error sending message: {response.text}")

    def send_audio_message(
        self, chat_context_entity: ChatContextEntity
    ) -> None:
        """
        Sends an audio message in the given chat context.
        """
        raise NotImplementedError(
            "send_audio_message function not implemented yet."
        )

    def get_messages(
        self,
        chat_context_entity: ChatContextEntity,
    ) -> dict[str, Any]:
        """
        Fetches messages from the Instagram messaging API for a given username.
        Queries can include an optional date to fetch messages from that date onward.
        Parses the response to find conversations involving the specified username.
        """
        raise NotImplementedError("get_messages function not implemented yet.")
