import { inject, provide, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { ATTACHMENT_TYPES } from './constants';

const MessageControl = Symbol('MessageControl');

/**
 * @typedef {Object} Attachment
 * @property {number} id - Unique identifier for the attachment
 * @property {number} messageId - ID of the associated message
 * @property {'image'|'audio'|'video'|'file'|'location'|'fallback'|'share'|'story_mention'|'contact'|'ig_reel'} fileType - Type of the attachment (file or image)
 * @property {number} accountId - ID of the associated account
 * @property {string|null} extension - File extension
 * @property {string} dataUrl - URL to access the full attachment data
 * @property {string} thumbUrl - URL to access the thumbnail version
 * @property {number} fileSize - Size of the file in bytes
 * @property {number|null} width - Width of the image if applicable
 * @property {number|null} height - Height of the image if applicable
 */

/**
 * @typedef {Object} Sender
 * @property {Object} additional_attributes - Additional attributes of the sender
 * @property {Object} custom_attributes - Custom attributes of the sender
 * @property {string} email - Email of the sender
 * @property {number} id - ID of the sender
 * @property {string|null} identifier - Identifier of the sender
 * @property {string} name - Name of the sender
 * @property {string|null} phone_number - Phone number of the sender
 * @property {string} thumbnail - Thumbnail URL of the sender
 * @property {string} type - Type of sender
 */

/**
 * @typedef {Object} EmailContent
 * @property {string[]|null} bcc - BCC recipients
 * @property {string[]|null} cc - CC recipients
 * @property {string} contentType - Content type of the email
 * @property {string} date - Date the email was sent
 * @property {string[]} from - From email address
 * @property {Object} htmlContent - HTML content of the email
 * @property {string} htmlContent.full - Full HTML content
 * @property {string} htmlContent.reply - Reply HTML content
 * @property {string} htmlContent.quoted - Quoted HTML content
 * @property {string|null} inReplyTo - Message ID being replied to
 * @property {string} messageId - Unique message identifier
 * @property {boolean} multipart - Whether the email is multipart
 * @property {number} numberOfAttachments - Number of attachments
 * @property {string} subject - Email subject line
 * @property {Object} textContent - Text content of the email
 * @property {string} textContent.full - Full text content
 * @property {string} textContent.reply - Reply text content
 * @property {string} textContent.quoted - Quoted text content
 * @property {string[]} to - To email addresses
 */

/**
 * @typedef {Object} ContentAttributes
 * @property {string} externalError - an error message to be shown if the message failed to send
 * @property {Object} [data] - Optional data object containing roomName and messageId
 * @property {string} data.roomName - Name of the room
 * @property {string} data.messageId - ID of the message
 * @property {'story_mention'} [imageType] - Flag to indicate this is a story mention
 * @property {'dyte'} [type] - Flag to indicate this is a dyte call
 * @property {EmailContent} [email] - Email content and metadata
 * @property {string|null} [ccEmail] - CC email addresses
 * @property {string|null} [bccEmail] - BCC email addresses
 */

/**
 * @typedef {'sent'|'delivered'|'read'|'failed'|'progress'} MessageStatus
 * @typedef {'text'|'input_text'|'input_textarea'|'input_email'|'input_select'|'cards'|'form'|'article'|'incoming_email'|'input_csat'|'integrations'|'sticker'} MessageContentType
 * @typedef {0|1|2|3} MessageType
 * @typedef {'contact'|'user'|'Contact'|'User'} SenderType
 * @typedef {'user'|'agent'|'activity'|'private'|'bot'|'error'|'template'|'email'|'unsupported'} MessageVariant
 * @typedef {'left'|'center'|'right'} MessageOrientation

 * @typedef {Object} MessageContext
 * @property {import('vue').Ref<string>} content - The message content
 * @property {import('vue').Ref<number>} conversationId - The ID of the conversation to which the message belongs
 * @property {import('vue').Ref<number>} createdAt - Timestamp when the message was created
 * @property {import('vue').Ref<number>} currentUserId - The ID of the current user
 * @property {import('vue').Ref<number>} id - The unique identifier for the message
 * @property {import('vue').Ref<number>} inboxId - The ID of the inbox to which the message belongs
 * @property {import('vue').Ref<boolean>} [groupWithNext=false] - Whether the message should be grouped with the next message
 * @property {import('vue').Ref<boolean>} [isEmailInbox=false] - Whether the message is from an email inbox
 * @property {import('vue').Ref<boolean>} [private=false] - Whether the message is private
 * @property {import('vue').Ref<number|null>} [senderId=null] - The ID of the sender
 * @property {import('vue').Ref<string|null>} [error=null] - Error message if the message failed to send
 * @property {import('vue').Ref<Attachment[]>} [attachments=[]] - The attachments associated with the message
 * @property {import('vue').Ref<ContentAttributes>} [contentAttributes={}] - Additional attributes of the message content
 * @property {import('vue').Ref<MessageContentType>} contentType - Content type of the message
 * @property {import('vue').Ref<MessageStatus>} status - The delivery status of the message
 * @property {import('vue').Ref<MessageType>} messageType - The type of message (must be one of MESSAGE_TYPES)
 * @property {import('vue').Ref<Object|null>} [inReplyTo=null] - The message to which this message is a reply
 * @property {import('vue').Ref<SenderType>} [senderType=null] - The type of the sender
 * @property {import('vue').Ref<Sender|null>} [sender=null] - The sender information
 * @property {import('vue').ComputedRef<MessageOrientation>} orientation - The visual variant of the message
 * @property {import('vue').ComputedRef<MessageVariant>} variant - The visual variant of the message
 * @property {import('vue').ComputedRef<boolean>} isBotOrAgentMessage - Does the message belong to the current user
 * @property {import('vue').ComputedRef<boolean>} isPrivate - Proxy computed value for private
 * @property {import('vue').ComputedRef<boolean>} shouldGroupWithNext - Should group with the next message or not, it is differnt from groupWithNext, this has a bypass for a failed message
 */

/**
 * Retrieves the message context from the parent Message component.
 * Must be used within a component that is a child of a Message component.
 *
 * @returns {MessageContext & { filteredCurrentChatAttachments: import('vue').ComputedRef<Attachment[]> }}
 * Message context object containing message properties and computed values
 * @throws {Error} If used outside of a Message component context
 */
export function useMessageContext() {
  const context = inject(MessageControl, null);
  if (context === null) {
    throw new Error(`Component is missing a parent <Message /> component.`);
  }

  const currentChatAttachments = useMapGetter('getSelectedChatAttachments');
  const filteredCurrentChatAttachments = computed(() => {
    const attachments = currentChatAttachments.value.filter(attachment =>
      [
        ATTACHMENT_TYPES.IMAGE,
        ATTACHMENT_TYPES.VIDEO,
        ATTACHMENT_TYPES.IG_REEL,
        ATTACHMENT_TYPES.AUDIO,
      ].includes(attachment.file_type)
    );

    return useSnakeCase(attachments);
  });

  return { ...context, filteredCurrentChatAttachments };
}

export function provideMessageContext(context) {
  provide(MessageControl, context);
}
