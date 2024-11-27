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
};

export const SENDER_TYPES = {
  CONTACT: 'Contact',
  USER: 'User',
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

export const MEDIA_TYPES = [
  ATTACHMENT_TYPES.IMAGE,
  ATTACHMENT_TYPES.VIDEO,
  ATTACHMENT_TYPES.AUDIO,
  ATTACHMENT_TYPES.IG_REEL,
];
