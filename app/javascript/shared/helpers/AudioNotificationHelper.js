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

export const shouldPlayByUserSettings = (enableAudioAlerts, id, userId) => {
  if (enableAudioAlerts === 'mine') {
    return userId === id;
  }
  if (enableAudioAlerts === 'all') {
    return true;
  }
  if (enableAudioAlerts === 'none') {
    return false;
  }
  return false;
};

export const shouldPlayByBrowserBehavior = (
  message,
  conversationId,
  userId,
  isDocHiddden
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
  return false;
};
export const getAssigneeFromNotification = currentConv => {
  let id;
  if (currentConv.meta) {
    const assignee = currentConv.meta.assignee;
    if (assignee) {
      id = assignee.id;
    }
  }
  return id;
};
export const newMessageNotification = data => {
  const { conversation_id: currentConvId } = window.WOOT.$route.params;
  const currentUserId = window.WOOT.$store.getters.getCurrentUserID;
  const { conversation_id: incomingConvId } = data;
  const currentConv =
    window.WOOT.$store.getters.getConversationById(incomingConvId) || {};
  const assigneeId = getAssigneeFromNotification(currentConv);
  const isDocHiddden = document.hidden;
  const {
    enable_audio_alerts: enableAudioAlerts = false,
  } = window.WOOT.$store.getters.getUISettings;
  const playAudio = shouldPlayByBrowserBehavior(
    data,
    currentConvId,
    currentUserId,
    isDocHiddden
  );
  const playAudioByUserSettings = shouldPlayByUserSettings(
    enableAudioAlerts,
    currentUserId,
    assigneeId
  );
  if (playAudio && playAudioByUserSettings) {
    window.playAudioAlert();
    showBadgeOnFavicon();
  }
};
