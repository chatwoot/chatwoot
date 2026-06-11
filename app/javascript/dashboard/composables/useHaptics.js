const canVibrate = () =>
  typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';

// iOS Safari has no Vibration API. The only way to reach the Taptic Engine
// from the web is the native HTML switch control (Safari/iOS 17.4+, see the
// WebKit 17.4 release notes): toggling an `<input type="checkbox" switch>`
// fires the system switch haptic. The toggle MUST happen synchronously inside
// a user gesture — transient user activation expires after an `await`, so
// callers fire haptics at tap time, never after a network round-trip.
// On platforms without the switch attribute the toggle is a silent no-op.
let switchLabel = null;
const ensureSwitchElement = () => {
  if (switchLabel?.isConnected) return switchLabel;

  switchLabel = document.createElement('label');
  switchLabel.setAttribute('aria-hidden', 'true');
  switchLabel.style.display = 'none';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.tabIndex = -1;
  input.setAttribute('switch', '');
  switchLabel.appendChild(input);
  document.body.appendChild(switchLabel);
  return switchLabel;
};

const tapticPulse = () => {
  try {
    ensureSwitchElement().click();
  } catch {
    // haptics are best-effort only
  }
};

// iOS exposes a single pulse intensity, so stronger feedback styles are
// emulated with multiple pulses, mirroring UIKit's notification haptics.
// Pulses are kept inside a short window so WebKit still treats the queued
// toggles as gesture-driven; later pulses may be dropped once activation
// expires, degrading gracefully to a single tick.
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
