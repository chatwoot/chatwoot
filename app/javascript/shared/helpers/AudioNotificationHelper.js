export const initOnEvents = ['click', 'touchstart', 'keypress', 'keydown'];

export const getAudioContext = () => {
  let audioCtx;
  try {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  } catch {
    // AudioContext is not available.
  }
  return audioCtx;
};

// eslint-disable-next-line default-param-last
export const getAlertAudio = async (baseUrl = '', requestContext) => {
  const { type = 'dashboard', alertTone = 'ding' } = requestContext || {};
  const resourceUrl = `${baseUrl}/audio/${type}/${alertTone}.mp3`;

  const audio = new Audio(resourceUrl);
  window.playAudioAlert = () => {
    audio.play().catch(() => {
      // Handle play() error
    });
  };

  return audio.load();
};
