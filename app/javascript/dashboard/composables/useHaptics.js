const canVibrate = () =>
  typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function';

const vibrate = pattern => {
  if (canVibrate()) navigator.vibrate(pattern);
};

export const useHaptics = () => ({
  light: () => vibrate(10),
  medium: () => vibrate(25),
  heavy: () => vibrate(50),
  success: () => vibrate([10, 50, 10]),
});
