import { MESSAGE_TYPE } from 'shared/constants/messages';
const notificationAudio = require('shared/assets/audio/ding.mp3');
import axios from 'axios';

export const playNotificationAudio = () => {
  try {
    new Audio(notificationAudio).play();
  } catch (error) {
    // error
  }
};

export const getAlertAudio = async () => {
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

const shouldPlayAudio = data => {
  const { conversation_id: currentConvId } = window.WOOT.$route.params;
  const currentUserId = window.WOOT.$store.getters.getCurrentUserID;
  const {
    conversation_id: incomingConvId,
    sender_id: senderId,
    message_type: messageType,
  } = data;
  const isFromCurrentUser = currentUserId === senderId;

  const playAudio =
    currentConvId !== incomingConvId &&
    !isFromCurrentUser &&
    messageType === MESSAGE_TYPE.INCOMING;
  return playAudio;
};

export const newMessageNotification = data => {
  const {
    enable_audio_alerts: enableAudioAlerts = false,
  } = window.WOOT.$store.getters.getUISettings;
  if (!enableAudioAlerts) return false;

  if (document.hidden) {
    window.playAudioAlert();
  } else {
    const playAudio = shouldPlayAudio(data);
    if (playAudio) {
      window.playAudioAlert();
    }
  }
  return false;
};
