"""
File for Whapi schemas.
"""

from typing import Any, Dict, List, Literal, Optional, Union

from llama_cloud import MessageRole
from pydantic import Field

from app.domain.entities.chat_entities import (
    ChatContextEntity,
    ChatMessageEntity,
    IChatMessage,
    IChatMessageCollection,
    LlamaIndexChatMessage,
    MediaEntity,
)
from app.domain.enums.chat_enums import MediaType, UnprocessedMediaTag
from app.infrastructure.models.schemas.base_schema import BaseSchema
from app.utils.datetime_utils import timestamp_to_datetime_utc
from app.utils.utils import ensure_non_empty_content


# region Chat Metadata Schemas


class WhapiLabel(BaseSchema):
    """
    Represents a label in Whapi chat metadata
    """

    id: str
    name: str
    color: str


class WhapiChatMetadata(BaseSchema):
    """
    Represents metadata for a Whapi chat
    """

    id: str
    type: str
    timestamp: int
    not_spam: bool
    name: Optional[str] = None
    labels: Optional[List[WhapiLabel]] = Field(default_factory=list)


# endregion


# region Common Content Schemas


class Button(BaseSchema):
    """
    Represents a button in messages that support them
    """

    type: str
    title: str
    id: str
    copy_code: Optional[str] = None
    phone_number: Optional[str] = None
    url: Optional[str] = None
    merchant_url: Optional[str] = None


class Section(BaseSchema):
    """
    Represents a section in messages that support them
    """

    title: str
    rows: List[Dict[str, str]]  # Contains title, description, id
    product_items: Optional[List[Dict[str, str]]] = (
        None  # Contains catalog_id, product_id
    )


class TextContent(BaseSchema):
    """
    Contains the text content of a message
    """

    id: Optional[str] = (
        None  # Only to keep interface compatibility with other content types here
    )
    body: str
    buttons: Optional[List[Button]] = None
    sections: Optional[List[Section]] = None
    button: Optional[str] = None
    view_once: Optional[bool] = None


class MediaContent(BaseSchema):
    """
    Base class for media content
    """

    id: str
    link: Optional[str] = ""
    mime_type: str
    file_size: int
    file_name: Optional[str] = None
    sha256: str
    timestamp: Optional[int] = None
    view_once: Optional[bool] = None


class ImageContent(MediaContent):
    """
    Contains image specific content
    """

    caption: Optional[str] = None
    preview: str
    width: int
    height: int
    buttons: Optional[List[Button]] = None


class VideoContent(MediaContent):
    """
    Contains video specific content
    """

    caption: Optional[str] = None
    preview: str
    width: int
    height: int
    seconds: int
    autoplay: Optional[bool] = True
    buttons: Optional[List[Button]] = None


class AudioContent(MediaContent):
    """
    Contains audio specific content
    """

    seconds: int
    recording_time: Optional[int] = None


class DocumentContent(MediaContent):
    """
    Contains document specific content
    """

    caption: Optional[str] = None
    filename: str
    page_count: int
    preview: str
    buttons: Optional[List[Button]] = None


class StickerContent(MediaContent):
    """
    Contains sticker specific content
    """

    animated: bool
    width: int
    height: int
    preview: str


class LocationContent(BaseSchema):
    """
    Contains location specific content
    """

    latitude: float
    longitude: float
    address: Optional[str] = None
    name: Optional[str] = None
    url: Optional[str] = None
    preview: Optional[str] = None
    accuracy: Optional[float] = None
    speed: Optional[float] = None
    degrees: Optional[float] = None
    comment: Optional[str] = None
    view_once: Optional[bool] = None


class LiveLocationContent(LocationContent):
    """
    Contains live location specific content
    """

    sequence_number: int
    time_offset: int
    caption: Optional[str] = None


class ContactContent(BaseSchema):
    """
    Contains contact specific content
    """

    name: str
    vcard: str
    view_once: Optional[bool] = None


class ContactListContent(BaseSchema):
    """
    Contains contact list specific content
    """

    list: List[ContactContent]
    view_once: Optional[bool] = None


class InteractiveContent(BaseSchema):
    """
    Contains interactive specific content
    """

    header: Optional[Dict[str, str]] = None  # Contains text
    body: Dict[str, str]  # Contains text
    footer: Optional[Dict[str, str]] = None  # Contains text
    action: Dict[str, Any]  # Contains list or buttons or product
    type: str
    view_once: Optional[bool] = None


class PollContent(BaseSchema):
    """
    Contains poll specific content
    """

    title: str
    options: List[str]
    vote_limit: Optional[int] = None
    total: int
    results: List[Dict[str, Any]]  # Contains id, name, count, voters
    view_once: Optional[bool] = None


class AdContent(BaseSchema):
    """
    Represents ad content in a message
    """

    title: str
    body: str
    media_type: str
    preview_url: str
    source: Dict[str, str]  # Contains id, type, url
    attrib: bool
    ctwa: str


class Context(BaseSchema):
    """
    Contains context information for a message
    """

    forwarded: Optional[bool] = None
    forwarding_score: Optional[int] = None
    mentions: Optional[List[str]] = None
    quoted_id: Optional[str] = None
    quoted_type: Optional[str] = None
    quoted_content: Optional[Dict[str, Any]] = None
    quoted_author: Optional[str] = None
    ephemeral: Optional[int] = None
    conversion: Optional[Dict[str, Any]] = None
    ad: Optional[AdContent] = None


class Action(BaseSchema):
    """
    Contains action information for a message
    """

    target: Optional[str] = None
    type: Optional[str] = None
    emoji: Optional[str] = None
    ephemeral: Optional[int] = None
    edited_type: Optional[str] = None
    edited_content: Optional[Dict[str, Any]] = None
    votes: Optional[List[str]] = None
    comment: Optional[str] = None


# endregion


# region Chat Message Schemas


class WhapiChatMessage(BaseSchema):
    """
    Base class for all Whapi messages
    """

    type: str
    id: str
    subtype: Optional[str] = None
    from_me: bool
    chat_id: str
    chat_name: Optional[str] = None
    source: str
    timestamp: int
    from_: str = Field(..., alias="from")
    from_name: Optional[str] = Field(None, alias="fromName")
    device_id: Optional[int] = None
    status: Optional[str] = None
    context: Optional[Context] = None
    action: Optional[Action] = None


class WhapiTextMessage(WhapiChatMessage, IChatMessage):
    """Message type for text messages"""

    type: Literal[MediaType.TEXT]
    text: TextContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the instance's attributes and context information into a list of
        `ChatMessageEntity` objects, preserving roles, message content, and metadata.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        # Content to be returned, handle ad content if present
        content = self.text.body
        # Check if there's ad content in the context
        if self.context and self.context.ad:
            ad_content = self.context.ad
            ad_text = f"\n{UnprocessedMediaTag.AD}\nTitle: {ad_content.title}\nDescription: {ad_content.body}"
            content += ad_text

        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(content),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiImageMessage(WhapiChatMessage, IChatMessage):
    """Message type for image messages"""

    type: Literal[MediaType.IMAGE]
    image: ImageContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current object into a list of ChatMessageEntity instances.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        content: str = ensure_non_empty_content(self.image.caption)
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(content),
                    role=message_role,
                ),
                media=MediaEntity(
                    external_id=self.image.id,
                    media_type=MediaType.IMAGE,
                    media_url=self.image.link,
                    preview=self.image.preview,
                    mime_type=self.image.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiVideoMessage(WhapiChatMessage, IChatMessage):
    """Message type for video messages"""

    type: Literal[MediaType.VIDEO]
    video: VideoContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts a ChatContextEntity into a list of ChatMessageEntity objects with detailed
        mappings for roles, messages, media, and other metadata attributes. Utilizes properties
        of the input ChatContextEntity and the current instance to create structured
        ChatMessageEntity objects.
        """
        message_role = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=UnprocessedMediaTag.VIDEO,
                    role=message_role,
                ),
                media=MediaEntity(
                    external_id=self.video.id,
                    media_type=MediaType.VIDEO,
                    media_url=self.video.link,
                    preview=self.video.preview,
                    mime_type=self.video.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiAudioMessage(WhapiChatMessage, IChatMessage):
    """Message type for audio messages"""

    type: Literal[MediaType.AUDIO]
    audio: AudioContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Generates a list of ChatMessageEntity objects based on the
        current instance and the provided chat context. It converts
        information from the instance to the structure required for
        integration with the ChatMessageEntity representation.
        """
        message_role = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        media_url = self.audio.link or ""
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=UnprocessedMediaTag.AUDIO,
                    role=message_role,
                ),
                media=MediaEntity(
                    external_id=self.audio.id,
                    media_type=MediaType.AUDIO,
                    media_url=media_url,
                    mime_type=self.audio.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiDocumentMessage(WhapiChatMessage, IChatMessage):
    """Message type for document messages"""

    type: Literal[MediaType.DOCUMENT]
    document: DocumentContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current instance to a list of ChatMessageEntity objects based on the
        provided ChatContextEntity. This process involves mapping attributes from the current
        instance and chat context to create ChatMessageEntity instances with appropriate
        metadata and media configurations.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=UnprocessedMediaTag.DOCUMENT,
                    role=message_role,
                ),
                media=MediaEntity(
                    external_id=self.document.id,
                    media_type=MediaType.DOCUMENT,
                    media_url=self.document.link,
                    preview=self.document.preview,
                    mime_type=self.document.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiStickerMessage(WhapiChatMessage, IChatMessage):
    """Message type for sticker messages"""

    type: Literal[MediaType.STICKER]
    sticker: StickerContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current entity into a list of ChatMessageEntity objects.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=UnprocessedMediaTag.STICKER,
                    role=message_role,
                ),
                media=MediaEntity(
                    external_id=self.sticker.id,
                    media_type=MediaType.STICKER,
                    media_url=self.sticker.link,
                    preview=self.sticker.preview,
                    mime_type=self.sticker.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiLocationMessage(WhapiChatMessage, IChatMessage):
    """Message type for location messages"""

    type: Literal[MediaType.LOCATION]
    location: LocationContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts location data to chat message entities.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        location_text: str = (
            f"{UnprocessedMediaTag.LOCATION}: {self.location.latitude}, {self.location.longitude}"
        )
        if self.location.name:
            location_text += f"\nName: {self.location.name}"
        if self.location.address:
            location_text += f"\nAddress: {self.location.address}"

        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(location_text),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={
                    "latitude": self.location.latitude,
                    "longitude": self.location.longitude,
                    "type": MediaType.LOCATION,
                },
            )
        ]


class WhapiLiveLocationMessage(WhapiChatMessage, IChatMessage):
    """Message type for live location messages"""

    type: Literal["live_location"]
    live_location: LiveLocationContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current entity's live location details into a list
        of ChatMessageEntity objects for further processing in the given
        chat context.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        location_text: str = (
            f"{UnprocessedMediaTag.LIVE_LOCATION}: {self.live_location.latitude}, {self.live_location.longitude}"
        )
        if self.live_location.caption:
            location_text += f"\nCaption: {self.live_location.caption}"

        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(location_text),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={
                    "latitude": self.live_location.latitude,
                    "longitude": self.live_location.longitude,
                    "type": MediaType.LIVE_LOCATION,
                    "sequence_number": self.live_location.sequence_number,
                    "time_offset": self.live_location.time_offset,
                },
            )
        ]


class WhapiContactMessage(WhapiChatMessage, IChatMessage):
    """Message type for contact messages"""

    type: Literal[MediaType.CONTACT]
    contact: ContactContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts a chat message entity into a list of `ChatMessageEntity` objects
        with message details filled based on provided chat context. It identifies
        the role of the message (e.g., assistant or user) and encapsulates the
        message content, metadata, timestamp, and reference to relevant chat session.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=f"{UnprocessedMediaTag.CONTACT} {self.contact.vcard}",
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiContactListMessage(WhapiChatMessage, IChatMessage):
    """Message type for contact list messages"""

    type: Literal["contact_list"]
    contact_list: ContactListContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts a list of contacts' messages into a list of chat message entities,
        applying a given chat context. The function iterates over all contacts in the
        contact list, retrieves their corresponding chat message entity objects based on the given
        chat context, and combines them into a list. The resulting messages are sorted
        by their respective timestamps.
        """
        raise NotImplementedError(
            "to_chat_message_entities function not implemented yet in WhapiContactListMessage."
        )


class WhapiInteractiveMessage(WhapiChatMessage, IChatMessage):
    """Message type for interactive messages"""

    type: Literal[MediaType.INTERACTIVE]
    interactive: InteractiveContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts an object into a list of ChatMessageEntity objects based on
        the given chat context and encapsulates this object with relevant
        message attributes.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        content: str = (
            f"{UnprocessedMediaTag.INTERACTIVE_CONTENT}\n"
            f"{self.interactive.header.get('text', '')}\n"
            f"{self.interactive.body.get('text', '')}\n"
            f"{self.interactive.footer.get('text', '')}"
        )

        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(content),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiPollMessage(WhapiChatMessage, IChatMessage):
    """Message type for poll messages"""

    type: Literal[MediaType.POLL]
    poll: PollContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current poll message into a list of `ChatMessageEntity` objects
        based on the provided chat context. The method formats the poll content, associates
        metadata, and assigns a message role corresponding to the sender.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        poll_content: str = (
            f"{UnprocessedMediaTag.POLL}\n"
            f"{self.poll.title}\n"
            f"{'\n'.join(self.poll.options)}"
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(poll_content),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class WhapiVoiceMessage(WhapiChatMessage, IChatMessage):
    """Message type for voice messages"""

    type: Literal["voice"]
    voice: AudioContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts the current object into a list of ChatMessageEntity objects based on
        the provided chat context. The objects created will represent chat messages
        that include audio content with metadata such as role, media details, and
        timestamp information. The representation is suitable for integration with
        chat systems or message processing workflows.
        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=UnprocessedMediaTag.AUDIO.value, role=message_role
                ),
                media=MediaEntity(
                    media_type=MediaType.AUDIO,
                    media_url=self.voice.link,
                    mime_type=self.voice.mime_type,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={},
            )
        ]


class LinkPreviewContent(BaseSchema):
    """
    Contains link preview specific content
    """

    body: str
    url: str
    canonical: Optional[str] = None
    title: str
    description: Optional[str] = None
    preview: Optional[str] = None
    id: Optional[str] = None
    sha256: Optional[str] = None


class WhapiLinkPreviewMessage(WhapiChatMessage, IChatMessage):
    """Message type for link preview messages"""

    type: Literal["link_preview"]
    link_preview: LinkPreviewContent

    def to_chat_message_entities(
        self, chat_context_entity: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Convert the current instance to a list of ChatMessageEntity objects based
        on the given ChatContextEntity.

        """
        message_role: MessageRole = (
            MessageRole.ASSISTANT if self.from_me else MessageRole.USER
        )
        content = self.link_preview.body

        # If there's a title and description, add them to the content
        if self.link_preview.title or self.link_preview.description:
            content_parts = [content]
            content_parts.append(f"\n{UnprocessedMediaTag.LINK}")

            if self.link_preview.title:
                content_parts.append(f"Title: {self.link_preview.title}")

            if self.link_preview.description:
                content_parts.append(
                    f"Description: {self.link_preview.description}"
                )

            if self.link_preview.url:
                content_parts.append(f"URL: {self.link_preview.url}")

            content = "\n".join(content_parts)

        return [
            ChatMessageEntity(
                external_id=self.id,
                chat_session_id=chat_context_entity.chat_session.id,
                message_role=message_role,
                message=LlamaIndexChatMessage(
                    content=ensure_non_empty_content(content),
                    role=message_role,
                ),
                sent_date=timestamp_to_datetime_utc(self.timestamp),
                message_metadata={
                    "url": self.link_preview.url,
                    "title": self.link_preview.title,
                    "description": self.link_preview.description,
                    "type": MediaType.LINK,
                },
            )
        ]


# Defines all possible Whapi chat message types
AnyWhapiChatMessage = Union[
    WhapiTextMessage,
    WhapiImageMessage,
    WhapiVoiceMessage,
    WhapiAudioMessage,
    WhapiDocumentMessage,
    WhapiLocationMessage,
    WhapiLinkPreviewMessage,
    dict,
    # TODO: Add the rest of messages, for now they'll be treated as dict to ignore
    # WhapiStickerMessage,
    # WhapiContactMessage,
    # WhapiLiveLocationMessage,
    # WhapiVideoMessage,
    # WhapiContactListMessage,
    # WhapiInteractiveMessage,
    # WhapiPollMessage,
]


class WhapiChatMessageCollection(BaseSchema, IChatMessageCollection):
    """Collection of Whapi chat messages"""

    messages: List[AnyWhapiChatMessage]
    count: int
    total: int

    def to_chat_message_entities(
        self, chat_context: ChatContextEntity
    ) -> List[ChatMessageEntity]:
        """
        Converts chat messages to a list of ChatMessageEntity.
        """
        messages = []
        for message in self.messages:
            if isinstance(message, IChatMessage):
                messages.extend(message.to_chat_message_entities(chat_context))

        # Sort messages by timestamp
        messages.sort(key=lambda msg: msg.sent_date)
        return messages


# endregion


# region Send Message Schemas
class SendWhapiChatMessage(BaseSchema):
    """
    Base schema for sending messages via Whapi
    """

    to: str  # External ID of the chat session
    quoted: str = "Naga8Rv6-U7yZc49ra8Vr."
    # ephemeral: Optional[int] = None  # For temporary messages
    edit: str = "RIbrj9HEj9bnl.P9TTV-4U97l4WPz"
    mentions: List[str] = []
    view_once: bool = False


class SendWhapiTextMessage(SendWhapiChatMessage):
    """
    Schema for sending text messages via Whapi
    """

    body: str
    typing_time: int = 0
    no_link_preview: bool = False


class SendWhapiImageMessage(SendWhapiChatMessage):
    """
    Schema for sending image messages via Whapi
    """

    media: str
    mime_type: str
    caption: str = ""
    preview: str = ""
    width: int = 0
    height: int = 0
    no_encode: bool = False
    no_cache: bool = False


class SendWhapiAudioMessage(SendWhapiChatMessage):
    """
    Schema for sending audio messages via Whapi
    """

    media: str
    mime_type: str
    seconds: Optional[int] = None
    recording_time: Optional[int] = None
    no_encode: Optional[bool] = None
    no_cache: Optional[bool] = None


class SendWhapiChatMessageResponse(BaseSchema):
    """
    Response schema for sending messages via Whapi
    """

    sent: bool
    message: WhapiChatMessage


# endregion
