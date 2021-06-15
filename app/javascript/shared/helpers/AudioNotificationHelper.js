import { MESSAGE_TYPE } from 'shared/constants/messages';
const notificationAudio = require('shared/assets/audio/ding.mp3');
import axios from 'axios';
import { showBadgeOnFavicon } from './faviconHelper';

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

export const shouldPlayAudio = (
  message,
  conversationId,
  userId,
  isDocHiddden,
  enableAudioAlerts,
  id
) => {
  const {
    conversation_id: incomingConvId,
    sender_id: senderId,
    message_type: messageType,
    private: isPrivate,
  } = message;
  const isFromCurrentUser = userId === senderId;

  const playAudio =
    !isFromCurrentUser && (messageType === MESSAGE_TYPE.INCOMING || isPrivate);

  if (isDocHiddden) return playAudio;
  if (conversationId !== incomingConvId) return playAudio;

  if (enableAudioAlerts === 'mine') {
    return userId === id;
  }
  if (enableAudioAlerts === 'all') {
    return playAudio;
  }
  if (enableAudioAlerts === 'none') {
    return !playAudio;
  }
  return false;
};

export const newMessageNotification = data => {
  const { conversation_id: currentConvId } = window.WOOT.$route.params;
  const currentUserId = window.WOOT.$store.getters.getCurrentUserID;
  const currentConv = window.WOOT.$store.getters.getConversationById(
    currentConvId
  );
  const assignee = currentConv.assignee;
  let id;

  if (assignee) {
    id = assignee.id;
  }
  const isDocHiddden = document.hidden;
  const {
    enable_audio_alerts: enableAudioAlerts = false,
  } = window.WOOT.$store.getters.getUISettings;

  const playAudio = shouldPlayAudio(
    data,
    currentConvId,
    currentUserId,
    isDocHiddden,
    enableAudioAlerts,
    id
  );

  if (playAudio) {
    window.playAudioAlert();
    showBadgeOnFavicon();
  }
};
