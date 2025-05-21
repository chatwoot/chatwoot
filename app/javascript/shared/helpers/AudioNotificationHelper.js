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
  const audioCtx = getAudioContext();
  const getSoundSource = (audioBuffer, loop, name) => {
    window[name] = () => {
      if (audioCtx) {
        const source = audioCtx.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(audioCtx.destination);
        source.loop = loop;
        return source;
      }
      return null;
    };
  };

  if (audioCtx) {
    const {
      type = 'dashboard',
      alertTone = 'ding',
      loop = false,
    } = requestContext || {};
    const resourceUrl = `${baseUrl}/audio/${type}/${alertTone}.mp3`;
    const audioRequest = new Request(resourceUrl);

    const array = await (await fetch(audioRequest)).arrayBuffer();

    const ctx = await audioCtx.decodeAudioData(array);

    getSoundSource(ctx, loop, alertTone);
  }
};

