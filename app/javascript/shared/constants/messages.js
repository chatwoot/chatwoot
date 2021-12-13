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

export const ALLOWED_FILE_TYPES =
  'image/gif, image/jpeg, image/png, image/bmp, image/tiff, image/webp' +
  'audio/aac, audio/midi, audio/x-midi, audio/mpeg, audio/ogg, audio/wav, audio/webm, audio/3gpp, audio/3gpp2' +
  'video/x-msvideo, video/mp4, video/mpeg, video/ogg, video/webm, video/3gpp, video/3gpp2' +
  'text/csv, text/plain, application/json, application/pdf' +
  'application/zip, application/x-7z-compressed application/vnd.rar application/x-tar' +
  'application/msword, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/vnd.oasis.opendocument.text' +
  'application/vnd.openxmlformats-officedocument.presentationml.presentation, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' +
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

export const CSAT_RATINGS = [
  {
    key: 'disappointed',
    emoji: '😞',
    value: 1,
    color: '#FDAD2A',
  },
  {
    key: 'expressionless',
    emoji: '😑',
    value: 2,
    color: '#FFC532',
  },
  {
    key: 'neutral',
    emoji: '😐',
    value: 3,
    color: '#FCEC56',
  },
  {
    key: 'grinning',
    emoji: '😀',
    value: 4,
    color: '#6FD86F',
  },
  {
    key: 'smiling',
    emoji: '😍',
    value: 5,
    color: '#44CE4B',
  },
];
