let currentAudio = null;

const playNextIfAdjacent = audio => {
  const container = audio.closest(
    '.message-bubble-container, .agent-message-wrap, .user-message-wrap'
  );
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

  const hasText = next.querySelector('.chat-bubble');
  const nextAudio = next.querySelector('audio');
  if (nextAudio && !hasText) {
    nextAudio.play();
  }
};

export const initializeSingleAudioPlayback = () => {
  document.addEventListener(
    'play',
    event => {
      const target = event.target;
      if (target.tagName !== 'AUDIO') return;
      if (currentAudio && currentAudio !== target) {
        currentAudio.pause();
      }
      currentAudio = target;
    },
    true
  );

  document.addEventListener(
    'ended',
    event => {
      const target = event.target;
      if (target.tagName !== 'AUDIO') return;
      playNextIfAdjacent(target);
      currentAudio = null;
    },
    true
  );
};