import axios from 'axios';

export const getWidgetAlertAudio = async () => {
  window.playAudioAlert = () => {};
  const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  const playsound = audioBuffer => {
    window.playAudioAlert = () => {
      const source = audioCtx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(audioCtx.destination);
      source.loop = false;
      source.start();
    };
  };
  try {
    const response = await axios.get('/dashboard/audios/ding.mp3', {
      responseType: 'arraybuffer',
    });
    audioCtx.decodeAudioData(response.data).then(playsound);
  } catch (error) {
    // error
  }
};
export const newMessageNotification = () => {
  window.playAudioAlert();
};
