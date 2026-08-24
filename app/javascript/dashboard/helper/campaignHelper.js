import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const BROADCAST_CHANNELS = {
  SMS: 'sms',
  WHATSAPP: 'whatsapp',
};

export const BROADCAST_STATUS = {
  SCHEDULED: 'scheduled',
  PROCESSING: 'processing',
  COMPLETED: 'completed',
};

/**
 * Resolves the broadcast channel a campaign belongs to from its inbox.
 * @param {Object} inbox - Inbox the campaign is sent from.
 * @returns {string} One of BROADCAST_CHANNELS.
 */
export const getBroadcastChannel = inbox => {
  const { channel_type: channelType, medium } = inbox ?? {};
  const isWhatsAppInbox =
    channelType === INBOX_TYPES.WHATSAPP ||
    (channelType === INBOX_TYPES.TWILIO && medium === 'whatsapp');

  return isWhatsAppInbox ? BROADCAST_CHANNELS.WHATSAPP : BROADCAST_CHANNELS.SMS;
};

/**
 * Resolves the display status of a broadcast campaign.
 * @param {Object} campaign - Broadcast campaign record.
 * @returns {string} One of BROADCAST_STATUS.
 */
export const getBroadcastStatus = campaign => {
  const { campaign_status: status } = campaign ?? {};

  if (status === BROADCAST_STATUS.COMPLETED) return BROADCAST_STATUS.COMPLETED;
  if (status === BROADCAST_STATUS.PROCESSING)
    return BROADCAST_STATUS.PROCESSING;

  return BROADCAST_STATUS.SCHEDULED;
};

// Liquid variables that can be interpolated into campaign messages and templates.
export const CAMPAIGN_MESSAGE_VARIABLES = [
  { key: 'CONTACT_NAME', name: 'contact.name' },
  { key: 'CONTACT_PHONE_NUMBER', name: 'contact.phone_number' },
  { key: 'AGENT_NAME', name: 'agent.name' },
  { key: 'ACCOUNT_NAME', name: 'account.name' },
].map(variable => ({ ...variable, token: `{{ ${variable.name} }}` }));

/**
 * Inserts a variable token at the cursor position of a textarea/input element.
 * @param {HTMLTextAreaElement|HTMLInputElement} element - Field receiving the token.
 * @param {string} value - Current value of the field.
 * @param {string} token - Variable token to insert.
 * @returns {{ value: string, cursorPosition: number }} Updated value and caret position.
 */
export const insertVariableAtCursor = (element, value, token) => {
  const start = element?.selectionStart ?? value.length;
  const end = element?.selectionEnd ?? value.length;
  const updatedValue = `${value.slice(0, start)}${token}${value.slice(end)}`;

  return { value: updatedValue, cursorPosition: start + token.length };
};

/**
 * Replaces liquid variables with sample values for preview purposes.
 * @param {string} body - Message body containing liquid variables.
 * @param {Object} sampleValues - Map of variable names to sample values.
 * @returns {string} Message body with sample values applied.
 */
export const renderWithSampleValues = (body, sampleValues) =>
  (body ?? '').replace(
    /{{\s*([\w.]+)\s*}}/g,
    (match, name) => sampleValues[name] ?? match
  );
