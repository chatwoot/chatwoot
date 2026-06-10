const canVibrate = () =>
  typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';

// iOS Safari has no Vibration API. The only way to reach the Taptic Engine
// from the web is the native HTML switch (iOS 17.4+): toggling an
// `<input type="checkbox" switch>` via a label click inside a user gesture
// fires a real system haptic. On platforms without the switch attribute the
// toggle is a silent no-op.
const tapticPulse = () => {
  try {
    const label = document.createElement('label');
    label.ariaHidden = 'true';
    label.style.display = 'none';
    const input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    label.appendChild(input);
    document.head.appendChild(label);
    label.click();
    document.head.removeChild(label);
  } catch {
    // haptics are best-effort only
  }
};

// iOS exposes a single pulse intensity, so stronger feedback styles are
// emulated with multiple pulses, mirroring UIKit's notification haptics.
const tapticBurst = (count, interval = 120) => {
  tapticPulse();
  for (let index = 1; index < count; index += 1) {
    setTimeout(tapticPulse, interval * index);
  }
};

const haptic = (pattern, { pulses = 1, interval = 120 } = {}) => {
  if (canVibrate()) {
    navigator.vibrate(pattern);
    return;
  }
  tapticBurst(pulses, interval);
};

export const useHaptics = () => ({
  // UIImpactFeedbackGenerator equivalents
  light: () => haptic(10),
  medium: () => haptic(25),
  heavy: () => haptic(50, { pulses: 2, interval: 80 }),
  // UISelectionFeedbackGenerator equivalent
  selection: () => haptic(5),
  // UINotificationFeedbackGenerator equivalents
  success: () => haptic([10, 50, 10], { pulses: 2 }),
  error: () => haptic([40, 60, 40, 60, 40], { pulses: 3, interval: 100 }),
});
