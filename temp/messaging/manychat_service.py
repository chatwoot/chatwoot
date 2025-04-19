"""
This module contains a concrete implementation of the MessagingService using Manychat
"""

import asyncio
import time
from typing import Any, Dict, List, Optional
from uuid import UUID, uuid4

import httpx
import requests
from injector import inject
from requests import Response

from app.config import settings
from app.domain.abstract_classes.services.messaging_service import (
    MessagingPlatformService,
)
from app.domain.entities.chat_entities import (
    ChatContextEntity,
    ChatMessageEntity,
    ChatSessionEntity,
    IChatMessageCollection,
    ImageToSendEntity,
)
from app.domain.entities.store_config_entities import ManychatConfigEntity
from app.domain.entities.store_entities import StoreEntity
from app.domain.entities.user_entities import UserMetadataEntity
from app.domain.enums.chat_enums import Channel
from app.domain.enums.messaging_enums import TagType
from app.infrastructure.models.schemas.services.manychat_internal_schema import (
    IGInMessageContainer,
    IGMessagesResponse,
    LoadThreadsResponse,
    SendWAImagesRequest,
    SendWAImagesResponse,
    UploadImageResponse,
    WAInMessageContainer,
    WAMessagesResponse,
)
from app.infrastructure.models.schemas.services.manychat_schema import (
    CardElement,
    DynamicBlock,
    DynamicBlockContent,
    GalleryMessage,
    ManychatSubscriberInfo,
    Message,
)
from app.utils.log_utils import logger


MANYCHAT_PUBLIC_API_BASE_URL: str = "https://api.manychat.com"
MANYCHAT_INTERNAL_API_BASE_URL: str = "https://app.manychat.com"
BASE_CHAT_LINK: str = "https://app.manychat.com/{page_id}/chat/{subscriber_id}"

chat_channel_keys: Dict[Channel, str] = {
    Channel.INSTAGRAM: "optin_instagram",
    Channel.WHATSAPP: "optin_whatsapp",
}


class ManychatService(MessagingPlatformService):
    """
    Concrete Implementation of Messaging platform for Manychat
    """

    @inject
    def __init__(self) -> None:
        pass

    async def _send_text_message(
        self,
        chat_context_entity: ChatContextEntity,
        message: str,
    ) -> Optional[dict]:
        """
        Send a simple text message to a specific subscriber.
        """
        if not message:
            return None
        retries: int = 0
        # TODO: remove the hardcoded max_retries
        max_retries: int = 2
        while retries < max_retries:
            try:
                message_obj = Message(type="text", text=message)
                content = DynamicBlockContent(
                    type=chat_context_entity.chat_session.channel,
                    messages=[message_obj],
                )
                dynamic_block = DynamicBlock(content=content)
                return await self.__send_dynamic_block(
                    chat_context_entity, dynamic_block
                )
            except Exception as e:  # pylint: disable=broad-exception-caught
                retries += 1
                logger.log_exception(
                    e,
                    f"Failed to send text message (attempt {retries})",
                    extra={
                        "subscriber_id": chat_context_entity.chat_session.external_id,
                        "text": message[:100],
                    },
                )
        return None

    async def send_image_message(
        self, chat_context_entity: ChatContextEntity, image: ImageToSendEntity
    ) -> dict:
        """
        Send an image message to a specific user
        """
        raise NotImplementedError(
            "send_image_message function not implemented yet."
        )

    async def send_audio_message(self, chat_context_entity: ChatContextEntity) -> Any:  # type: ignore
        """
        Send an audio message to a given chat context. This function is meant for
        asynchronous execution and is currently not implemented.
        """
        raise NotImplementedError(
            "send_audio_message function not implemented yet."
        )

    async def send_images_catalog(
        self,
        chat_context_entity: ChatContextEntity,
        images_entities_catalog: List[ImageToSendEntity],
    ) -> Any:
        """
        Sends a group of images as a catalog, depending on the channel.
        """
        channel: Optional[Channel] = chat_context_entity.chat_session.channel
        if channel == Channel.INSTAGRAM:
            # Instagram - Build images as gallery / carousel
            elements = []
            for image in images_entities_catalog:
                element = CardElement(
                    title=image.title,
                    subtitle=image.caption,
                    image_url=image.url,
                )
                elements.append(element)
            gallery_message: GalleryMessage = GalleryMessage(
                type="cards", elements=elements, image_aspect_ratio="horizontal"
            )
            content: DynamicBlockContent = DynamicBlockContent(
                type=channel.value,
                messages=[gallery_message],
                actions=[],
                quick_replies=[],
            )
            catalog_dynamic_block: DynamicBlock = DynamicBlock(
                version="v2", content=content
            )

            # Send the catalog to the user
            return await self.__send_dynamic_block(
                chat_context_entity,
                catalog_dynamic_block,
            )
        if channel == Channel.WHATSAPP:
            # WhatsApp - Send images through internal API
            return self.__send_whatsapp_images(
                chat_context_entity, images_entities_catalog
            )
        else:
            raise ValueError(f"Unsupported channel: {channel}")

    async def tag_user(
        self,
        chat_context_entity: ChatContextEntity,
        tag: TagType,
    ) -> dict:
        """
        Tag a specific subscriber (user) using the ManyChat API.
        """
        subscriber_id: Optional[str] = (
            chat_context_entity.chat_session.external_id
        )
        tag_id: str = self.__get_tag_id(chat_context_entity, tag)
        # TODO: Remove the try/catch since the error should be caught in the usages of the function
        try:
            url: str = f"{MANYCHAT_PUBLIC_API_BASE_URL}/fb/subscriber/addTag"
            headers: Dict = self.__get_public_headers(chat_context_entity)
            payload: Dict[str, Optional[str]] = {
                "subscriber_id": subscriber_id,
                "tag_id": tag_id,
            }

            response: Response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=settings.REQUEST_TIMEOUT_IN_SECONDS,
            )
            response.raise_for_status()  # Raise an exception for HTTP errors
            return response.json()  # type: ignore[no-any-return]
        except requests.exceptions.RequestException as e:
            logger.log_exception(
                e,
                "Failed to tag subscriber",
                extra={"subscriber_id": subscriber_id, "tag_id": tag},
            )

    async def get_user_metadata(
        self, chat_context_entity: ChatContextEntity
    ) -> UserMetadataEntity:
        """
        Fetches user information from the ManyChat API using a subscriber ID.
        """
        subscriber_id: Optional[str] = (
            chat_context_entity.chat_session.external_id
        )
        url: str = f"{MANYCHAT_PUBLIC_API_BASE_URL}/fb/subscriber/getInfo"
        headers: Dict = self.__get_public_headers(chat_context_entity)
        params: Dict[str, Optional[str]] = {"subscriber_id": subscriber_id}

        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers, params=params)
            response.raise_for_status()
            data = response.json()
            subscriber_data = data.get("data", {})
            subscriber_info = ManychatSubscriberInfo(**subscriber_data)
            return subscriber_info.to_user_metadata_entity()

    async def get_messages(
        self,
        chat_context_entity: ChatContextEntity,
    ) -> IChatMessageCollection:
        """
        Fetches messages from Manychat using provided configuration and parameters.
        """
        subscriber_id: Optional[str] = (
            chat_context_entity.chat_session.external_id
        )
        store_entity: StoreEntity = chat_context_entity.store
        channel: Optional[Channel] = chat_context_entity.chat_session.channel

        return await self.__load_messages(
            subscriber_id=subscriber_id,
            store=store_entity,
            channel=channel,
        )

    async def get_latest_chats_for_recovery(
        self, store_entity: StoreEntity, channel: Channel
    ) -> List[str]:
        """
        Retrieves latest chats from Manychat for a specific channel.

        Returns the list of external IDs of the chats that need recovery.
        """
        threads_response = await self.__load_threads(
            store_entity=store_entity,
            channel=channel,
            limit=store_entity.conversation_config.max_chats_to_load,
        )

        # Process all threads in parallel
        async def process_thread_messages(thread):
            thread_messages = await self.__load_messages(
                subscriber_id=thread.user_id,
                store=store_entity,
                channel=channel,
            )
            if (
                hasattr(thread_messages, "messages")
                and thread_messages.messages
            ):
                last_message = thread_messages.messages[0]
                if self.__is_incoming_message(last_message):
                    return thread.user.user_id
            return None

        # Gather all thread processing tasks
        results = await asyncio.gather(
            *[
                process_thread_messages(thread)
                for thread in threads_response.threads
            ]
        )

        # Filter out None values and return valid external IDs
        return [id for id in results if id is not None]

    def get_chat_link(
        self,
        chat_context_entity: ChatContextEntity,
    ) -> str:
        """
        Creates a link that points to the specific chat in the specific platform
        """
        manychat_config: ManychatConfigEntity = (
            MessagingPlatformService.get_channel_config(
                chat_context_entity, ManychatConfigEntity
            )
        )
        chat_session: Optional[ChatSessionEntity] = (
            chat_context_entity.chat_session
        )
        chat_link: str = BASE_CHAT_LINK.format(
            page_id=manychat_config.page_id,
            subscriber_id=chat_session.external_id,
        )
        return chat_link

    async def fetch_message_media(
        self,
        chat_message_entity: ChatMessageEntity,
        chat_context_entity: ChatContextEntity,
    ) -> ChatMessageEntity:
        """
        Fetches and processes media content associated with a chat message based on the given
        chat message data and context. The function ensures any relevant media tied to the
        chat message is handled appropriately.
        """
        raise NotImplementedError(
            "fetch_message_media function not implemented yet."
        )

    # region Private Functions
    def __get_manychat_config(
        self, store_entity: StoreEntity, channel: Channel
    ) -> ManychatConfigEntity:
        """
        Retrieves the Manychat configuration for the specified channel and store.
        """
        return getattr(store_entity.messaging_config, channel)

    def __get_tag_id(
        self, chat_context_entity: ChatContextEntity, tag: TagType
    ) -> str:
        """
        Gets the corresponding Manychat tag ID for a TagType enum value.
        """
        # Get tags per current channel
        channel: Optional[Channel] = chat_context_entity.chat_session.channel
        tag_ids = getattr(
            chat_context_entity.store.messaging_config, channel
        ).tags
        tag_id: str = getattr(tag_ids, tag)
        return tag_id

    def __get_public_headers(self, chat_context: ChatContextEntity) -> dict:
        """
        Generates headers required for ManyChat API requests.
        """
        manychat_config: ManychatConfigEntity = (
            MessagingPlatformService.get_channel_config(
                chat_context, ManychatConfigEntity
            )
        )
        return {
            "Authorization": f"Bearer {manychat_config.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def __get_internal_headers(
        self, manychat_config: ManychatConfigEntity
    ) -> Dict[str, str]:
        """
        Generates and returns a dictionary of HTTP headers required for Manychat API requests.
        """
        return {
            "x-csrf-token": manychat_config.csrf_token,
            "x-frontend-bundle": manychat_config.frontend_bundle,
            "x-requested-with": "XMLHttpRequest",
            "referer": f"https://manychat.com/{manychat_config.page_id}/chat",
            "origin": "https://manychat.com",
            "content-type": "application/json",
            "accept": "*/*",
        }

    def __get_session(
        self,
        manychat_config: ManychatConfigEntity,
    ) -> httpx.AsyncClient:
        """
        Initializes and returns an HTTPX asynchronous client session with predefined cookies.
        """
        session = httpx.AsyncClient()
        session.cookies.set(
            "mc_production-main", manychat_config.cookie, domain="manychat.com"
        )
        return session

    def __is_incoming_message(self, message: Any) -> bool:
        """
        Checks if the message is an incoming message.
        """
        return isinstance(message, (WAInMessageContainer, IGInMessageContainer))

    async def __send_dynamic_block(
        self,
        chat_context_entity: ChatContextEntity,
        dynamic_block: DynamicBlock,
    ) -> dict:
        """
        Send a dynamic block to a specific subscriber using the ManyChat API.
        """
        subscriber_id: Optional[str] = (
            chat_context_entity.chat_session.external_id
        )
        url: str = f"{MANYCHAT_PUBLIC_API_BASE_URL}/fb/sending/sendContent"
        headers: Dict = self.__get_public_headers(chat_context_entity)
        payload: Dict[str, Optional[str]] = {
            "subscriber_id": subscriber_id,
            "data": dynamic_block.model_dump(),
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                url,
                json=payload,
                headers=headers,
                timeout=settings.REQUEST_TIMEOUT_IN_SECONDS,
            )
            response.raise_for_status()  # Raise an exception for HTTP errors
            json_response: Dict = response.json()
            return json_response

    async def __make_request(
        self,
        method: str,
        endpoint: str,
        manychat_config: ManychatConfigEntity,
        store_id: UUID,
        subscriber_id: Optional[str] = None,
        params: Optional[dict] = None,
        data: Optional[dict] = None,
        files: Optional[dict] = None,
    ) -> Any:
        """
        Makes an HTTP request to a Manychat API endpoint and returns the JSON response.
        """
        url: str = f"{MANYCHAT_INTERNAL_API_BASE_URL}/{endpoint}"
        headers: Dict[str, Optional[str]] = self.__get_internal_headers(
            manychat_config
        )

        try:
            async with self.__get_session(manychat_config) as session:
                if files:
                    headers.pop("content-type", None)
                    response = await session.request(
                        method,
                        url,
                        params=params,
                        files=files,
                        headers=headers,
                    )
                else:
                    response = await session.request(
                        method,
                        url,
                        params=params,
                        json=data,
                        headers=headers,
                    )
                response.raise_for_status()
                json_response: Dict = response.json()
                return json_response
        except httpx.RequestError as e:
            logger.log_exception(
                e,
                f"Request error during {method} {endpoint}",
                extra={
                    "store_id": str(store_id),
                    "subscriber_id": subscriber_id,
                },
            )
            raise

    async def __upload_image(
        self,
        chat_context_entity: ChatContextEntity,
        image: ImageToSendEntity,
    ) -> Optional[UploadImageResponse]:
        """
        Downloads an image from the provided URL and uploads it to ManyChat.
        """
        manychat_config = MessagingPlatformService.get_channel_config(
            chat_context_entity, ManychatConfigEntity
        )
        subscriber_id: Optional[str] = (
            chat_context_entity.chat_session.external_id
        )
        endpoint: str = f"{manychat_config.page_id}/content/upload"

        max_retries: int = 3
        delay_seconds: int = 2

        for attempt in range(1, max_retries + 1):
            try:
                async with httpx.AsyncClient() as client:
                    # Download the image from the URL
                    response = await client.get(
                        image.url,
                        timeout=settings.REQUEST_TIMEOUT_IN_SECONDS,
                    )
                    response.raise_for_status()

                    # Get content type and extension
                    content_type = response.headers.get(
                        "Content-Type", ""
                    ).lower()
                    extension = (
                        ".jpg"
                        if "jpeg" in content_type or "jpg" in content_type
                        else ".png"
                    )
                    filename = f"image_{uuid4()}{extension}"

                    # Pass the content directly in the files dictionary
                    files = {"0": (filename, response.content, content_type)}

                    response_data = await self.__make_request(
                        method="POST",
                        endpoint=endpoint,
                        manychat_config=manychat_config,
                        store_id=chat_context_entity.store.id,
                        files=files,
                        subscriber_id=subscriber_id,
                    )
                    return UploadImageResponse(**response_data)

            except httpx.RequestError as e:
                logger.log_exception(
                    e,
                    f"Attempt {attempt}: Failed to download image from URL",
                    extra={
                        "subscriber_id": chat_context_entity.chat_session.external_id,
                        "image_url": image.url,
                    },
                )
            except Exception as e:  # pylint: disable=broad-exception-caught
                logger.log_exception(
                    e,
                    f"Attempt {attempt}: Failed to upload image",
                    extra={
                        "subscriber_id": chat_context_entity.chat_session.external_id,
                        "image_url": image.url,
                    },
                )

            if attempt < max_retries:
                await asyncio.sleep(delay_seconds)
            else:
                logger.error(
                    "Max retries reached. Failed to upload image.",
                    extra={
                        "subscriber_id": chat_context_entity.chat_session.external_id,
                        "image_url": image.url,
                    },
                )
                raise Exception(
                    "Failed to upload image after multiple attempts"
                )

    async def __send_whatsapp_images(
        self,
        chat_context_entity: ChatContextEntity,
        images: List[ImageToSendEntity],
    ) -> SendWAImagesResponse:
        """
        Sends a list of images to a subscriber via WhatsApp using the ManyChat API.
        """
        try:
            # Upload all images and collect their attachment IDs
            attachment_ids = []
            for image in images:
                # TODO: Cache images with a table of attachment IDs or similar
                upload_response = await self.__upload_image(
                    chat_context_entity, image
                )
                attachment_ids.append(upload_response.attachment.caid)

            payload = SendWAImagesRequest(
                user_id=chat_context_entity.chat_session.external_id,
                timestamp=time.time(),
                pause_automation=True,
                attachment_id=attachment_ids,
            )

            endpoint: str = (
                f"{chat_context_entity.store.messaging_config.page_id}/im/sendWhatsAppMessage?clear_question_context=true"
            )
            manychat_config = self.__get_manychat_config(
                chat_context_entity.store,
                chat_context_entity.chat_session.channel,
            )

            response = await self.__make_request(
                method="POST",
                endpoint=endpoint,
                manychat_config=manychat_config,
                store_id=chat_context_entity.store.id,
                subscriber_id=chat_context_entity.chat_session.external_id,
                data=payload.model_dump(),
            )

            return SendWAImagesResponse.model_validate(response)

        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.log_exception(
                e,
                "Failed to send WhatsApp images",
                extra={
                    "subscriber_id": chat_context_entity.chat_session.external_id
                },
            )
            raise

    async def __load_messages(
        self,
        subscriber_id: str,
        store: StoreEntity,
        channel: Channel,
    ) -> IChatMessageCollection:
        """
        Call loadMessages endpoint to retrieve messages from Manychat
        """
        manychat_config: ManychatConfigEntity = self.__get_manychat_config(
            store, channel
        )

        # Define request parameters
        method: str = "GET"
        endpoint: str = f"{manychat_config.page_id}/im/loadMessages"
        params: Dict[str, Any] = {
            "limit": 50,
            "user_id": subscriber_id,
            "type": str(channel.value),
        }

        response_data = await self.__make_request(
            method=method,
            endpoint=endpoint,
            manychat_config=manychat_config,
            store_id=store.id,
            subscriber_id=subscriber_id,
            params=params,
        )

        if "errors" in response_data and len(response_data["errors"]) > 0:
            error_messages = "\n".join(response_data["errors"])
            raise Exception(
                f"Errors encountered: {error_messages} for subscriber_id: {subscriber_id}"
            )

        # Parse response based on channel
        if channel == Channel.INSTAGRAM:
            return IGMessagesResponse.model_validate(response_data)
        return WAMessagesResponse.model_validate(response_data)

    async def __load_threads(
        self,
        store_entity: StoreEntity,
        channel: Channel,
        limit: int,
    ) -> LoadThreadsResponse:
        """
        Loads threads from Manychat for a specific channel.
        """
        manychat_config: ManychatConfigEntity = self.__get_manychat_config(
            store_entity, channel
        )

        payload = {
            "limit": limit,
            "sorting": "newest",
            "filter": {
                "operator": "AND",
                "groups": [
                    {
                        "operator": "AND",
                        "items": [
                            {
                                "type": "suf",
                                "field": chat_channel_keys[channel],
                                "operator": "TRUE",
                                "value": None,
                            }
                        ],
                    }
                ],
            },
            "status": "open",
            "folder": "all",
        }

        endpoint: str = f"{manychat_config.page_id}/im/loadThreads"
        response_data = await self.__make_request(
            method="POST",
            endpoint=endpoint,
            manychat_config=manychat_config,
            store_id=store_entity.id,
            subscriber_id=None,
            data=payload,
        )

        return LoadThreadsResponse.model_validate(response_data)

    # endregion
