import { ref } from 'vue';
import { getAlertAudio } from 'shared/helpers/AudioNotificationHelper';

export function useRingtone(intervalMs = 2500) {
  const timer = ref(null);
  const stop = () => {
    if (timer.value) {
      clearInterval(timer.value);
      timer.value = null;
    }
    if (typeof window.stopAudioAlert === 'function') {
      window.stopAudioAlert();
    }
  };

  const play = () => {
    if (typeof window.playAudioAlert === 'function') {
      window.playAudioAlert();
    }
  };

  const start = async () => {
    stop();
    if (typeof window.playAudioAlert !== 'function') {
      await getAlertAudio('', { type: 'dashboard', alertTone: 'call-ring' });
    }
    play();
    timer.value = setInterval(() => {
      play();
    }, intervalMs);
  };

  return { start, stop };
}
