const AUDIO_EXTENSION_MAP = {
  'audio/ogg': 'ogg',
  'audio/mp3': 'mp3',
  'audio/mpeg': 'mp3',
  'audio/wav': 'wav',
  'audio/webm': 'webm',
};

// MediaRecorder types can carry codec parameters, e.g. "audio/ogg; codecs=opus".
export const getAudioFileExtension = mimeType => {
  const baseType = (mimeType || '').split(';')[0].trim().toLowerCase();
  return AUDIO_EXTENSION_MAP[baseType] || 'mp3';
};
