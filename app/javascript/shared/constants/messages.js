export const MESSAGE_STATUS = {
  FAILED: 'failed',
  SENT: 'sent',
  PROGRESS: 'progress',
};

export const MESSAGE_TYPE = {
  INCOMING: 0,
  OUTGOING: 1,
  ACTIVITY: 2,
  TEMPLATE: 3,
};
// Size in mega bytes
export const MAXIMUM_FILE_UPLOAD_SIZE = 40;

export const CSAT_RATINGS = [
  {
    key: 'disappointed',
    emoji: '😞',
    value: 0,
  },
  {
    key: 'expressionless',
    emoji: '😑',
    value: 1,
  },
  {
    key: 'neutral',
    emoji: '😐',
    value: 2,
  },
  {
    key: 'grinning',
    emoji: '😀',
    value: 3,
  },
  {
    key: 'smiling',
    emoji: '😍',
    value: 4,
  },
];
