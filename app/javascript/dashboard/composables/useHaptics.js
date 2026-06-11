const canVibrate = () =>
  typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';

// iOS Safari has no Vibration API. Until iOS 26.4 the workaround was toggling
// a hidden `<input type="checkbox" switch>` (Safari/iOS 17.4+) from script,
// which fired the system switch haptic. iOS 26.5 patched programmatic
// toggles: only a trusted user tap landing directly on a switch control still
// reaches the Taptic Engine. Tap-driven surfaces therefore overlay a
// transparent switch via the `vHapticTap` directive
// (components-next/mobile/hapticTap.js); the programmatic path below remains
// for iOS 17.4-26.4 and for gesture-driven feedback (swipe thresholds,
// pull-to-refresh), where no real tap hits a switch.
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

// Set by vHapticTap when a trusted tap toggles an overlay switch: the system
// haptic already fired for that interaction, so the programmatic burst is
// skipped to avoid double feedback on iOS <= 26.4 (on 26.5+ the burst is a
// silent no-op anyway).
let trustedTapTimestamp = -Infinity;
export const notifyTrustedHapticTap = () => {
  trustedTapTimestamp = performance.now();
};
const trustedTapHandledHaptic = () =>
  performance.now() - trustedTapTimestamp < 400;

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
  if (trustedTapHandledHaptic()) return;
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
