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

export const getAllConversationsByAssignee = (conversations, currentUserId) => {
  const allConversationsByAssignee = [];
  conversations.forEach(conv => {
    if (currentUserId) {
      allConversationsByAssignee.push(conv);
    }
  });
  return allConversationsByAssignee;
};

export const getUnreadCountFromAllConversations = conversations => {
  let unreadCount = 0;
  conversations.forEach(conv => {
    unreadCount += conv.unread_count;
  });
  return unreadCount;
};

export const playAudioEvery30Seconds = () => {
  const {
    enable_audio_alerts: enableAudioAlerts = false,
    play_audio_until_all_conversations_are_read: playAudioUntilAllConversationsAreRead,
  } = window.WOOT.$store.getters.getUISettings;
  const currentUserId = window.WOOT.$store.getters.getCurrentUserID;

  if (enableAudioAlerts !== 'none' && playAudioUntilAllConversationsAreRead) {
    const allConversations = window.WOOT.$store.getters.getAllConversations;
    const allConversationsByUserId = getAllConversationsByAssignee(
      allConversations,
      currentUserId
    );
    const unreadCountFromAllConversations = getUnreadCountFromAllConversations(
      allConversationsByUserId
    );

    if (unreadCountFromAllConversations > 0) {
      window.playAudioAlert();
      showBadgeOnFavicon();
      setTimeout(() => {
        playAudioEvery30Seconds();
      }, 30000);
    } else {
      clearTimeout();
    }
  }
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

  const getAlertTone = alertType => {
    if (alertType === 'dashboard') {
      const {
        notification_tone: tone,
      } = window.WOOT.$store.getters.getUISettings;
      return tone;
    }
    return 'ding';
  };

  if (audioCtx) {
    const alertTone = getAlertTone(type);
    const resourceUrl = `${baseUrl}/audio/${type}/${alertTone}.mp3`;
    const audioRequest = new Request(resourceUrl);
    playAudioEvery30Seconds();

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
    play_audio_when_tab_is_inactive: playAudioWhenTabIsInactive,
  } = window.WOOT.$store.getters.getUISettings;
  const isDocHidden = playAudioWhenTabIsInactive ? document.hidden : true;

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
