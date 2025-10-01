import { ref } from 'vue';
import { getAlertAudio } from 'shared/helpers/AudioNotificationHelper';

export function useRingtone(intervalMs = 2500) {
  const timer = ref(null);
  const stop = () => {
    if (timer.value) {
      clearInterval(timer.value);
      timer.value = null;
    }
    try {
      if (typeof window.stopAudioAlert === 'function') {
        window.stopAudioAlert();
      }
    } catch (_) {
      // ignore stop errors
    }
  };

  const play = () => {
    if (typeof window.playAudioAlert === 'function') {
      window.playAudioAlert();
    }
  };

  const start = async () => {
    stop();
    try {
      if (typeof window.playAudioAlert !== 'function') {
        await getAlertAudio('', { type: 'dashboard', alertTone: 'call-ring' });
      }
    } catch (_) {
      // ignore preload errors
    }
    play();
    timer.value = setInterval(() => {
      play();
    }, intervalMs);
  };

  return { start, stop };
}
