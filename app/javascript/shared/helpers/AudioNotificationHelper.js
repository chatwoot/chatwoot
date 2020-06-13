const notificationAudio = require('shared/assets/audio/ding.mp3');

export const playNotificationAudio = () => {
  try {
    new Audio(notificationAudio).play();
    if (window.bus) window.bus.$emit('on-agent-message-recieved');
  } catch (error) {
    console.log(error);
  }
};
