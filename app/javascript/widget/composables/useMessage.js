import { computed } from 'vue';

/**
 * Composable for handling message-related computations.
 * @param {Object} message - The message object to be processed.
 * @returns {Object} An object containing computed properties for message content and attachments.
 */
export function useMessage(message) {
  const messageContentAttributes = computed(() => {
    const { content_attributes: attribute = {} } = message;
    return attribute;
  });

  const hasAttachments = computed(() => {
    return !!(message.attachments && message.attachments.length > 0);
  });

  return {
    messageContentAttributes,
    hasAttachments,
  };
}
