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

export const getAlertAudio = async (baseUrl = '', requestContext) => {
  const audioCtx = getAudioContext();
  const playSound = audioBuffer => {
    window.playAudioAlert = () => {
      if (audioCtx) {
        const source = audioCtx.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(audioCtx.destination);
        source.loop = false;
        source.start();
      }
    };
  };

  if (audioCtx) {
    const { type = 'dashboard', alertTone = 'ding' } = requestContext || {};
    const resourceUrl = `${baseUrl}/audio/${type}/${alertTone}.mp3`;
    const audioRequest = new Request(resourceUrl);

    fetch(audioRequest)
      .then(response => response.arrayBuffer())
      .then(buffer => {
        audioCtx.decodeAudioData(buffer).then(playSound);
        return new Promise(res => res());
      })
      .catch(() => {
        // error
      });
  }
};
