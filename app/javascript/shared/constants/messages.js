export const MESSAGE_STATUS = {
  FAILED: 'failed',
  SENT: 'sent',
  DELIVERED: 'delivered',
  READ: 'read',
  PROGRESS: 'progress',
};

export const MESSAGE_TYPE = {
  INCOMING: 0,
  OUTGOING: 1,
  ACTIVITY: 2,
  TEMPLATE: 3,
};

export const CONVERSATION_STATUS = {
  OPEN: 'open',
  RESOLVED: 'resolved',
  PENDING: 'pending',
  SNOOZED: 'snoozed',
};

export const CONVERSATION_PRIORITY = {
  URGENT: 'urgent',
  HIGH: 'high',
  LOW: 'low',
  MEDIUM: 'medium',
};

export const CONVERSATION_PRIORITY_ORDER = {
  urgent: 4,
  high: 3,
  medium: 2,
  low: 1,
};

// Size in mega bytes
export const MAXIMUM_FILE_UPLOAD_SIZE = 40;

export const ALLOWED_FILE_TYPES =
  'image/*,' +
  'audio/*,' +
  'video/*,' +
  '.3gpp,' +
  'text/csv, text/plain, application/json, application/pdf, text/rtf,' +
  'application/xml, text/xml,' +
  'application/zip, application/x-7z-compressed application/vnd.rar application/x-tar,' +
  'application/msword, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/vnd.oasis.opendocument.text,' +
  'application/vnd.openxmlformats-officedocument.presentationml.presentation, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,' +
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document,';

export const CSAT_RATINGS = [
  {
    key: 'disappointed',
    translationKey: 'CSAT.RATINGS.POOR',
    emoji: '😞',
    value: 1,
    color: '#FDAD2A',
  },
  {
    key: 'expressionless',
    translationKey: 'CSAT.RATINGS.FAIR',
    emoji: '😑',
    value: 2,
    color: '#FFC532',
  },
  {
    key: 'neutral',
    translationKey: 'CSAT.RATINGS.AVERAGE',
    emoji: '😐',
    value: 3,
    color: '#FCEC56',
  },
  {
    key: 'grinning',
    translationKey: 'CSAT.RATINGS.GOOD',
    emoji: '😀',
    value: 4,
    color: '#6FD86F',
  },
  {
    key: 'smiling',
    emoji: '😍',
    translationKey: 'CSAT.RATINGS.EXCELLENT',
    value: 5,
    color: '#44CE4B',
  },
];

export const CSAT_DISPLAY_TYPES = {
  EMOJI: 'emoji',
  STAR: 'star',
};

export const AUDIO_FORMATS = {
  WEBM: 'audio/webm',
  OGG: 'audio/ogg',
  MP3: 'audio/mp3',
  WAV: 'audio/wav',
};

export const MESSAGE_VARIABLES = [
  {
    label: 'Conversation Id',
    key: 'conversation.id',
  },
  {
    label: 'Contact Id',
    key: 'contact.id',
  },
  {
    label: 'Contact name',
    key: 'contact.name',
  },
  {
    label: 'Contact first name',
    key: 'contact.first_name',
  },
  {
    label: 'Contact last name',
    key: 'contact.last_name',
  },
  {
    label: 'Contact email',
    key: 'contact.email',
  },
  {
    label: 'Contact phone',
    key: 'contact.phone',
  },
  {
    label: 'Agent name',
    key: 'agent.name',
  },
  {
    label: 'Agent first name',
    key: 'agent.first_name',
  },
  {
    label: 'Agent last name',
    key: 'agent.last_name',
  },
  {
    label: 'Agent email',
    key: 'agent.email',
  },
  {
    key: 'inbox.name',
    label: 'Inbox name',
  },
  {
    label: 'Inbox id',
    key: 'inbox.id',
  },
];

export const ATTACHMENT_ICONS = {
  image: 'image',
  audio: 'headphones-sound-wave',
  video: 'video',
  file: 'document',
  location: 'location',
  fallback: 'link',
};

export const TWILIO_CONTENT_TEMPLATE_TYPES = {
  TEXT: 'text',
  MEDIA: 'media',
  QUICK_REPLY: 'quick_reply',
};
