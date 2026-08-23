import { ref } from 'vue';

const soundEnabled = ref(true);

// Generate a short notification beep using Web Audio API
// No external files needed — works offline, zero network cost
let audioContext = null;

function getAudioContext() {
  if (!audioContext) {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }
  return audioContext;
}

function playBeep(frequency = 880, duration = 120, volume = 0.3) {
  if (!soundEnabled.value) return;
  try {
    const ctx = getAudioContext();
    const oscillator = ctx.createOscillator();
    const gainNode = ctx.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);

    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(frequency, ctx.currentTime);
    oscillator.frequency.exponentialRampToValueAtTime(
      frequency * 0.5,
      ctx.currentTime + duration / 1000
    );

    gainNode.gain.setValueAtTime(volume, ctx.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(
      0.001,
      ctx.currentTime + duration / 1000
    );

    oscillator.start(ctx.currentTime);
    oscillator.stop(ctx.currentTime + duration / 1000);
  } catch (e) {
    // Web Audio not supported — silently ignore
  }
}

export function useNotificationSound() {
  const playMessageReceived = () => playBeep(880, 120, 0.25);
  const playNotification = () => {
    playBeep(660, 100, 0.2);
    setTimeout(() => playBeep(880, 150, 0.25), 120);
  };

  const toggleSound = () => {
    soundEnabled.value = !soundEnabled.value;
    return soundEnabled.value;
  };

  return {
    soundEnabled,
    playMessageReceived,
    playNotification,
    toggleSound,
  };
}
