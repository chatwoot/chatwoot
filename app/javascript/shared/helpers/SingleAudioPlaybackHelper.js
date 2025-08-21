const MESSAGE_CONTAINERS =
  '.message-bubble-container, .agent-message-wrap, .user-message-wrap';
const AUDIO_BUBBLE_SELECTOR = '[data-bubble-name="audio"] audio';
const CHAT_BUBBLE_SELECTOR = '.chat-bubble';

let isInitialized = false;
let currentAudio = null;

const playNextIfAdjacent = audio => {
  const container = audio.closest(MESSAGE_CONTAINERS);
  if (!container) return;
  const next = container.nextElementSibling;
  if (!next) return;

  const nextBubble = next.querySelector('[data-bubble-name]');
  if (nextBubble) {
    if (nextBubble.dataset.bubbleName === 'audio') {
      nextBubble.querySelector('audio')?.play();
    }
    return;
  }

  const hasText = next.querySelector(CHAT_BUBBLE_SELECTOR);
  const nextAudio = next.querySelector(AUDIO_BUBBLE_SELECTOR);
  if (nextAudio && !hasText) {
    nextAudio.play();
  }
};

const onAnyAudioPlay = e => {
  if (!(e.target instanceof HTMLAudioElement)) return;
  if (currentAudio && currentAudio !== e.target) {
    try {
      currentAudio.pause();
    } catch (_) {
      // Autoplay may be blocked; ignore
    }
  }
  currentAudio = e.target;
};

const onAnyAudioPause = e => {
  if (!(e.target instanceof HTMLAudioElement)) return;
  if (currentAudio === e.target) currentAudio = null;
};

const onAnyAudioEnd = e => {
  if (!(e.target instanceof HTMLAudioElement)) return;
  playNextIfAdjacent(e.target);
  if (currentAudio === e.target) currentAudio = null;
};

export const initSingleAudioManager = () => {
  if (isInitialized) return;
  document.addEventListener('play', onAnyAudioPlay, true);
  document.addEventListener('pause', onAnyAudioPause, true);
  document.addEventListener('ended', onAnyAudioEnd, true);
  isInitialized = true;
};
