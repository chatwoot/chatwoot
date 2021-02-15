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
    const { conversation_id: incomingConvId, sender_id: senderId } = data;
    const isFromCurrentUser = currentUserId === senderId;

    if (currentPageId !== incomingConvId && !isFromCurrentUser) {
      playAudioFromIframe();
    }
  }
};
