"""
This module contains a concrete implementation of the MessagingService using Whapi
"""

import asyncio
from typing import Any, Dict, List, Optional

import httpx
from injector import inject

from app.domain.abstract_classes.services.messaging_service import (
    MessagingPlatformService,
)
from app.domain.entities.chat_entities import (
    ChatContextEntity,
    ChatMessageEntity,
    IChatMessageCollection,
    ImageToSendEntity,
)
from app.domain.entities.store_config_entities import WhapiConfigEntity
from app.domain.entities.store_entities import StoreEntity
from app.domain.entities.user_entities import UserMetadataEntity
from app.domain.enums.chat_enums import Channel
from app.domain.enums.messaging_enums import TagType
from app.infrastructure.models.schemas.services.whapi_schema import (
    SendWhapiChatMessageResponse,
    SendWhapiImageMessage,
    SendWhapiTextMessage,
    WhapiChatMessageCollection,
    WhapiChatMetadata,
)
from app.utils.log_utils import logger


BASE_API_URL: str = "https://gate.whapi.cloud/"
BASE_CHAT_LINK: str = "https://wa.me/{wa_number}"
CHAT_ID_SUFFIX: str = "@s.whatsapp.net"
MAX_RETRY_ATTEMPTS: int = 2
RETRY_DELAY_SECONDS: int = 5


class WhapiService(MessagingPlatformService):
    """
    Concrete Implementation of Messaging platform for Whapi
    """

    @inject
    def __init__(self) -> None:
        self.api_url = BASE_API_URL.rstrip("/")

    # region Private Methods
    def __get_headers(self, chat_context: ChatContextEntity) -> Dict[str, str]:
        """
        Generates headers required for Whapi API requests.
        """
        # Here, we assume that WhatsApp configration object is a WhapiConfigEntity
        whapi_config: WhapiConfigEntity = (
            MessagingPlatformService.get_channel_config(
                chat_context, WhapiConfigEntity
            )
        )
        return {
            "Authorization": f"Bearer {whapi_config.api_key}",
            "Accept": "application/json",
        }

    async def _make_request(
        self,
        method: str,
        endpoint: str,
        chat_context: ChatContextEntity,
        params: Optional[dict] = None,
        payload: Optional[dict] = None,
        retry_attempts: int = MAX_RETRY_ATTEMPTS,
    ) -> Any:
        """
        Makes an HTTP request to the Whapi API endpoint and returns the JSON response.
        Includes automatic wake-up retry logic if the initial request fails.
        """
        url = f"{self.api_url}/{endpoint.lstrip('/')}"
        headers = self.__get_headers(chat_context)

        for attempt in range(retry_attempts + 1):
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.request(
                        method,
                        url,
                        params=params,
                        json=payload,
                        headers=headers,
                    )
                    response.raise_for_status()
                    return response.json()
            except (httpx.RequestError, httpx.HTTPStatusError) as e:
                if attempt == retry_attempts:  # Last attempt failed
                    logger.log_exception(
                        e,
                        f"Final attempt failed for {method} {endpoint} after {retry_attempts} retries",
                        extra={
                            "channel_id": chat_context.chat_session.external_id,
                            "status_code": (
                                getattr(e.response, "status_code", None)
                                if isinstance(e, httpx.HTTPStatusError)
                                else None
                            ),
                            "response_text": (
                                getattr(e.response, "text", None)
                                if isinstance(e, httpx.HTTPStatusError)
                                else None
                            ),
                        },
                    )
                    raise

                # Not the last attempt, try waking up the service
                logger.info(
                    f"Request attempt {attempt + 1} failed, attempting to wake up Whapi service"
                )
                await self.__check_health_wakeup(chat_context)

                # Wait before retrying
                await asyncio.sleep(RETRY_DELAY_SECONDS)

    def __labels_to_tags(
        self, chat_metadata: WhapiChatMetadata, whapi_config: WhapiConfigEntity
    ) -> List[TagType]:
        """
        Matches Whapi labels with configured tags and returns corresponding TagTypes
        """
        # Get all configured tag IDs from the config
        configured_tag_ids = vars(whapi_config.tags)

        converted_tags = []
        for label in chat_metadata.labels:
            try:
                # Only process labels that match our configured IDs
                if label.id not in configured_tag_ids.values():
                    continue

                # Try to create TagType from the label name
                tag_type = TagType(label.name.lower())
                converted_tags.append(tag_type)
            except ValueError:
                # Skip labels that don't match TagType values
                continue

        return converted_tags

    def __chat_metadata_to_user_metadata(
        self, chat_metadata: WhapiChatMetadata, whapi_config: WhapiConfigEntity
    ) -> UserMetadataEntity:
        """
        Transforms WhapiChatMetadata to UserMetadataEntity
        """
        return UserMetadataEntity(
            type="whapi",
            first_name=chat_metadata.name,  # Using chat name as first_name
            wa_phone=chat_metadata.id.split("@")[
                0
            ],  # Extract phone from chat ID
            tags=self.__labels_to_tags(chat_metadata, whapi_config),
        )

    async def __check_health_wakeup(
        self, chat_context: ChatContextEntity
    ) -> Dict[str, Any]:
        """
        Checks the health status of the Whapi service and attempts to wake it up.
        """
        endpoint = "health"
        params = {
            "wakeup": "true",
            "platform": "Chrome,Whapi,1.6.0",
            "channel_type": "web",
        }

        try:
            response_data: Dict[str, Any] = await self._make_request(
                "GET", endpoint, chat_context, params=params
            )
            return response_data
        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.log_exception(
                e,
                "Failed to check Whapi health status",
                extra={"channel_id": chat_context.chat_session.external_id},
            )
            raise

    # endregion

    # region Public Methods
    async def get_messages(
        self,
        chat_context_entity: ChatContextEntity,
    ) -> IChatMessageCollection:
        """
        Fetches messages from Whapi using provided configuration and parameters.
        """
        chat_id = chat_context_entity.chat_session.external_id
        endpoint = f"messages/list/{chat_id}"
        params = {"count": 100}  # TODO: want to make this configurable

        response_data = await self._make_request(
            "GET",
            endpoint,
            chat_context_entity,
            params=params,
        )

        return WhapiChatMessageCollection.model_validate(response_data)

    async def _send_text_message(
        self,
        chat_context_entity: ChatContextEntity,
        message: str,
    ) -> Optional[SendWhapiChatMessageResponse]:
        """
        Sends a text message using the Whapi API
        """
        endpoint = "messages/text"

        # Create payload using SendWhapiTextMessage schema
        payload = SendWhapiTextMessage(
            to=chat_context_entity.chat_session.external_id, body=message
        ).model_dump()

        try:
            response_data = await self._make_request(
                "POST", endpoint, chat_context_entity, payload=payload
            )
            response = SendWhapiChatMessageResponse.model_validate(
                response_data
            )
            return response
        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.log_exception(
                e,
                "Failed to send text message",
                extra={
                    "channel_id": chat_context_entity.chat_session.external_id,
                    "message_content": message,
                },
            )
            return None

    async def send_image_message(
        self,
        chat_context_entity: ChatContextEntity,
        image_entity: ImageToSendEntity,
    ) -> Optional[SendWhapiChatMessageResponse]:
        """
        Send an image message to the specific user
        """
        endpoint = "messages/image"

        # Create payload using SendWhapiImageMessage schema
        payload = SendWhapiImageMessage(
            to=chat_context_entity.chat_session.external_id,
            media=image_entity.url,
            mime_type=image_entity.mime_type,
            caption=image_entity.caption,
        ).model_dump()

        try:
            response_data = await self._make_request(
                "POST", endpoint, chat_context_entity, payload=payload
            )
            response: SendWhapiChatMessageResponse = (
                SendWhapiChatMessageResponse.model_validate(response_data)
            )
            return response
        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.log_exception(
                e,
                "Failed to send image message",
                extra={
                    "channel_id": chat_context_entity.chat_session.external_id,
                    "image_data": image_entity.model_dump(),
                },
            )
            return None

    async def send_audio_message(
        self, chat_context_entity: ChatContextEntity
    ) -> Any:
        """
        Sends an audio message to the specific user
        """
        raise NotImplementedError(
            "send_audio_message function not implemented yet."
        )

    async def send_images_catalog(
        self,
        chat_context_entity: ChatContextEntity,
        images_entities_catalog: List[ImageToSendEntity],
    ) -> List[Optional[SendWhapiChatMessageResponse]]:
        """
        Sends multiple images sequentially using send_image_message
        """
        responses = []
        for image in images_entities_catalog:
            response = await self.send_image_message(chat_context_entity, image)
            responses.append(response)

        return responses

    async def tag_user(
        self,
        chat_context_entity: ChatContextEntity,
        tag: TagType,
    ) -> dict:
        """
        Tags a user with the specified TagType using Whapi's labels API
        """
        # Get the Whapi config
        whapi_config: WhapiConfigEntity = (
            MessagingPlatformService.get_channel_config(
                chat_context_entity, WhapiConfigEntity
            )
        )

        # Get the tag ID from the config using the TagType name
        tag_id = getattr(whapi_config.tags, str(tag))

        # Construct the endpoint
        chat_id = chat_context_entity.chat_session.external_id
        endpoint = f"labels/{tag_id}/{chat_id}"

        try:
            response_data: dict = await self._make_request(
                "POST", endpoint, chat_context_entity
            )
            return response_data
        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.log_exception(
                e,
                "Failed to tag user",
                extra={
                    "channel_id": chat_id,
                    "tag": str(tag),
                    "tag_id": tag_id,
                },
            )
            return {"success": False}

    async def get_user_metadata(
        self, chat_context_entity: ChatContextEntity
    ) -> UserMetadataEntity:
        """
        Fetches user metadata from Whapi API
        """
        # Get config at the top level
        whapi_config: WhapiConfigEntity = (
            MessagingPlatformService.get_channel_config(
                chat_context_entity, WhapiConfigEntity
            )
        )

        chat_id = chat_context_entity.chat_session.external_id
        endpoint = f"chats/{chat_id}"

        response_data = await self._make_request(
            "GET",
            endpoint,
            chat_context_entity,
        )

        chat_metadata = WhapiChatMetadata.model_validate(response_data)
        return self.__chat_metadata_to_user_metadata(
            chat_metadata, whapi_config
        )

    def get_chat_link(
        self,
        chat_context_entity: ChatContextEntity,
    ) -> str:
        """
        Returns the phone number of the chat, since Whapi doesn't use a chat link
        """
        chat_id = chat_context_entity.chat_session.external_id
        chat_link: str = BASE_CHAT_LINK.format(
            wa_number=chat_id.split(CHAT_ID_SUFFIX)[0]
        )
        return chat_link

    async def fetch_message_media(
        self,
        chat_message_entity: ChatMessageEntity,
        chat_context_entity: ChatContextEntity,
    ) -> ChatMessageEntity:
        """
        Retrieves media from messaging platform to get a URL (might be our redis)
        """
        raise NotImplementedError(
            "fetch_message_media function not implemented yet."
        )

    async def get_latest_chats_for_recovery(
        self, store_entity: StoreEntity, channel: Channel
    ) -> List[ChatMessageEntity]:
        """
        Retrieves the latest chats for recovery purposes.
        """
        raise NotImplementedError(
            "get_latest_chats_for_recovery function not implemented yet."
        )

    # endregion
