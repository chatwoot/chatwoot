/**
 * Helper functions for detecting group conversations
 */

/**
 * Checks if a conversation is a WhatsApp group conversation
 * @param {Object} conversation - The conversation object
 * @returns {boolean} - True if it's a WhatsApp group conversation
 */
export const isWhatsAppGroupConversation = conversation => {
  // Check if the contact inbox source_id contains @g.us (WhatsApp group identifier)
  const sourceId = conversation?.contact_inbox?.source_id;
  const isGroup = sourceId?.includes('@g.us') || false;

  return isGroup;
}; /**
 * Checks if a conversation should show sender names for incoming messages
 * Currently only applies to WhatsApp group conversations
 * @param {Object} conversation - The conversation object
 * @returns {boolean} - True if sender names should be shown
 */
export const shouldShowSenderNames = conversation => {
  return isWhatsAppGroupConversation(conversation);
};
