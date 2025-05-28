export const MESSAGE_TYPES = {
  INCOMING: 0,
  OUTGOING: 1,
  ACTIVITY: 2,
  TEMPLATE: 3,
};

export const MESSAGE_VARIANTS = {
  USER: 'user',
  AGENT: 'agent',
  ACTIVITY: 'activity',
  PRIVATE: 'private',
  BOT: 'bot',
  ERROR: 'error',
  TEMPLATE: 'template',
  EMAIL: 'email',
  UNSUPPORTED: 'unsupported',
};

export const SENDER_TYPES = {
  CONTACT: 'Contact',
  USER: 'User',
  AGENT_BOT: 'agent_bot',
  CAPTAIN_ASSISTANT: 'captain_assistant',
};

export const ORIENTATION = {
  LEFT: 'left',
  RIGHT: 'right',
  CENTER: 'center',
};

export const MESSAGE_STATUS = {
  SENT: 'sent',
  DELIVERED: 'delivered',
  READ: 'read',
  FAILED: 'failed',
  PROGRESS: 'progress',
};

export const ATTACHMENT_TYPES = {
  IMAGE: 'image',
  AUDIO: 'audio',
  VIDEO: 'video',
  FILE: 'file',
  LOCATION: 'location',
  FALLBACK: 'fallback',
  SHARE: 'share',
  STORY_MENTION: 'story_mention',
  CONTACT: 'contact',
  IG_REEL: 'ig_reel',
};

export const CONTENT_TYPES = {
  TEXT: 'text',
  INPUT_TEXT: 'input_text',
  INPUT_TEXTAREA: 'input_textarea',
  INPUT_EMAIL: 'input_email',
  INPUT_SELECT: 'input_select',
  CARDS: 'cards',
  FORM: 'form',
  ARTICLE: 'article',
  INCOMING_EMAIL: 'incoming_email',
  INPUT_CSAT: 'input_csat',
  INTEGRATIONS: 'integrations',
  STICKER: 'sticker',
};

export const MEDIA_TYPES = [
  ATTACHMENT_TYPES.IMAGE,
  ATTACHMENT_TYPES.VIDEO,
  ATTACHMENT_TYPES.AUDIO,
  ATTACHMENT_TYPES.IG_REEL,
];

/**
 * Strips survey URLs from message content for CSAT template messages
 * @param {string} content - The message content
 * @param {number} messageType - The message type
 * @param {string} contentType - The content type
 * @returns {string} - Content with survey URLs stripped if applicable
 */
export const stripSurveyUrlFromContent = (
  content,
  messageType,
  contentType
) => {
  if (
    messageType === MESSAGE_TYPES.TEMPLATE &&
    contentType === CONTENT_TYPES.INPUT_CSAT
  ) {
    return content
      ?.replace(/\s*https?:\/\/[^\s]+\/survey\/responses\/[a-f0-9-]+\s*/g, '')
      .trim();
  }
  return content;
};
