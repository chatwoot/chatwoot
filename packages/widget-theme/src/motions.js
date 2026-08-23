// [whisker] Launcher motion presets — injected once as global keyframes.
// Presets animate `.woot-widget-bubble` without touching upstream styles.

const KEYFRAMES = `
@keyframes ws-motion-bounce {
  0%, 100% { transform: translateY(0); }
  30% { transform: translateY(-10px); }
  50% { transform: translateY(2px); }
  70% { transform: translateY(-5px); }
}
@keyframes ws-motion-tada {
  0%, 100% { transform: scale(1) rotate(0deg); }
  25% { transform: scale(1.08) rotate(-4deg); }
  55% { transform: scale(1.12) rotate(4deg); }
  80% { transform: scale(1.05) rotate(-2deg); }
}
@keyframes ws-motion-wiggle {
  0%, 100% { transform: rotate(0deg); }
  20% { transform: rotate(-8deg); }
  45% { transform: rotate(7deg); }
  70% { transform: rotate(-4deg); }
}
@keyframes ws-motion-hop {
  0%, 100% { transform: translateY(0) scaleY(1); }
  25% { transform: translateY(-14px) scaleY(1.04); }
  45% { transform: translateY(0) scaleY(0.94); }
  60% { transform: translateY(-6px) scaleY(1.02); }
  75% { transform: translateY(0) scaleY(0.97); }
}
`;

const MOTION_CLASSES = {
  bounce: 'ws-motion-anim ws-motion--bounce',
  tada: 'ws-motion-anim ws-motion--tada',
  wiggle: 'ws-motion-anim ws-motion--wiggle',
  hop: 'ws-motion-anim ws-motion--hop',
};

let injected = false;

export const injectMotionStyles = () => {
  if (injected) return;
  const style = document.createElement('style');
  style.id = 'ws-widget-motions';
  style.textContent = KEYFRAMES;
  document.head.appendChild(style);
  injected = true;
};

export const motionClassFor = preset => MOTION_CLASSES[preset] || '';
