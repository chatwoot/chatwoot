const notificationAudio = require('shared/assets/audio/ding.mp3');

export const playNotificationAudio = () => {
  try {
    new Audio(notificationAudio).play();
  } catch (error) {
    console.log(error);
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
    }, 300);
  } catch (error) {
    console.log(error);
  }
};

export const newMessageNotification = data => {
  if (document.hidden) {
    playAudioFromIframe();
  } else {
    const { conversation_id: currentPageId } = window.WOOT.$route.params;
    const { conversation_id: incomingConvId } = data;
    if (currentPageId !== incomingConvId) {
      playAudioFromIframe();
    }
  }
};
