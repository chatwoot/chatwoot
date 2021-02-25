const notificationAudio = require('shared/assets/audio/ding.mp3');

export const playNotificationAudio = () => {
  try {
    new Audio(notificationAudio).play();
  } catch (error) {
    // error
  }
};

export const playAudioFromIframe = () => {
  try {
    const audioEl = document.querySelector('#notif-audio');
    audioEl.currentTime = 0;
    audioEl.play();
    audioEl.muted = false;

    setTimeout(() => {
      audioEl.muted = true;
      audioEl.pause();
    }, 100);
  } catch (error) {
    // error
  }
};

export const newMessageNotification = data => {
  if (document.hidden) {
    playAudioFromIframe();
  } else {
    const { conversation_id: currentPageId } = window.WOOT.$route.params;
    const currentUserId = window.WOOT.$store.getters.getCurrentUserID;
    const {
      enable_audio_alerts: enableAudioNotifications = false,
    } = window.WOOT.$store.getters.getUISettings;
    const { conversation_id: incomingConvId, sender_id: senderId } = data;
    const isFromCurrentUser = currentUserId === senderId;
    const playAudio =
      currentPageId !== incomingConvId &&
      !isFromCurrentUser &&
      enableAudioNotifications;

    if (playAudio) {
      playAudioFromIframe();
    }
  }
};
