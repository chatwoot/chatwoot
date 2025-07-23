export const REPLY_EDITOR_MODES = {
  REPLY: 'REPLY',
  NOTE: 'NOTE',
  AI_FEEDBACK: 'AI_FEEDBACK',
};

export const EDITOR_MODE_CONFIG = [
  {
    key: REPLY_EDITOR_MODES.REPLY,
    label: 'CONVERSATION.REPLYBOX.REPLY',
    icon: 'i-lucide-reply',
  },
  {
    key: REPLY_EDITOR_MODES.NOTE,
    label: 'CONVERSATION.REPLYBOX.PRIVATE_NOTE',
    icon: 'i-lucide-lock',
  },
  {
    key: REPLY_EDITOR_MODES.AI_FEEDBACK,
    label: 'CONVERSATION.REPLYBOX.AI_FEEDBACK_MODE',
    icon: 'i-lucide-message-square-text',
  },
];

export const CHAR_LENGTH_WARNING = {
  UNDER_50: 'characters remaining',
  NEGATIVE: 'characters over',
};
