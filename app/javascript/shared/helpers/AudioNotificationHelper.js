import { MESSAGE_TYPE } from 'shared/constants/messages';
import { IFrameHelper } from 'widget/helpers/utils';

import { showBadgeOnFavicon } from './faviconHelper';

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

const getAlertTone = alertType => {
  if (alertType === 'dashboard') {
    const {
      notification_tone: tone,
    } = window.WOOT.$store.getters.getUISettings;
    return tone;
  }
  return 'ding';
};

export const getAlertAudio = async (baseUrl = '', type = 'dashboard') => {
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
    const alertTone = getAlertTone(type);
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

export const notificationEnabled = (enableAudioAlerts, id, userId) => {
  if (enableAudioAlerts === 'mine') {
    return userId === id;
  }
  if (enableAudioAlerts === 'all') {
    return true;
  }
  return false;
};

export const shouldPlayAudio = (
  message,
  conversationId,
  userId,
  isDocHidden
) => {
  const {
    conversation_id: incomingConvId,
    sender_id: senderId,
    message_type: messageType,
    private: isPrivate,
  } = message;
  if (!isDocHidden && messageType === MESSAGE_TYPE.INCOMING) {
    showBadgeOnFavicon();
    return false;
  }
  const isFromCurrentUser = userId === senderId;

  const playAudio =
    !isFromCurrentUser && (messageType === MESSAGE_TYPE.INCOMING || isPrivate);
  if (isDocHidden) return playAudio;
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

  const {
    enable_audio_alerts: enableAudioAlerts = false,
    always_play_audio_alert: alwaysPlayAudioAlert,
  } = window.WOOT.$store.getters.getUISettings;
  const isDocHidden = alwaysPlayAudioAlert ? true : document.hidden;

  const playAudio = shouldPlayAudio(
    data,
    currentConvId,
    currentUserId,
    isDocHidden
  );
  const isNotificationEnabled = notificationEnabled(
    enableAudioAlerts,
    currentUserId,
    assigneeId
  );

  if (playAudio && isNotificationEnabled) {
    window.playAudioAlert();
    showBadgeOnFavicon();
  }
};

export const playNewMessageNotificationInWidget = () => {
  IFrameHelper.sendMessage({
    event: 'playAudio',
  });
};
