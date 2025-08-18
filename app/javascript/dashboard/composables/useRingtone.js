import { ref } from 'vue';

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

  const start = () => {
    stop();
    play();
    timer.value = setInterval(() => {
      play();
    }, intervalMs);
  };

  return { start, stop };
}
