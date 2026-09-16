// Detects the current OS using the modern User-Agent Client Hints API,
// falling back to userAgent parsing on Safari/Firefox where it is unavailable.
// Treats iPad on iOS 13+ (which spoofs Macintosh) as iOS via maxTouchPoints.

export const OS = Object.freeze({
  MAC: 'macos',
  WINDOWS: 'windows',
  LINUX: 'linux',
  ANDROID: 'android',
  IOS: 'ios',
  UNKNOWN: 'unknown',
});

// navigator.userAgentData.platform → OS constant (lowercased keys)
const UAD_MAP = {
  macos: OS.MAC,
  windows: OS.WINDOWS,
  linux: OS.LINUX,
  android: OS.ANDROID,
  ios: OS.IOS,
};

export function detectOS() {
  if (typeof navigator === 'undefined') return OS.UNKNOWN;

  // Trust userAgentData only when it maps to a known OS; otherwise fall
  // through to UA parsing so unmapped values (e.g. "Chrome OS") don't leak.
  const uad = navigator.userAgentData?.platform?.toLowerCase();
  if (uad && UAD_MAP[uad]) return UAD_MAP[uad];

  const ua = navigator.userAgent || '';
  if (/android/i.test(ua)) return OS.ANDROID;
  if (/iPhone|iPod/.test(ua)) return OS.IOS;
  if (
    /iPad/.test(ua) ||
    (/Macintosh/.test(ua) && (navigator.maxTouchPoints || 0) > 1)
  ) {
    return OS.IOS;
  }
  if (/Win/i.test(ua)) return OS.WINDOWS;
  if (/Mac/i.test(ua)) return OS.MAC;
  if (/Linux/i.test(ua)) return OS.LINUX;

  return OS.UNKNOWN;
}

export const isApple = () => {
  const os = detectOS();
  return os === OS.MAC || os === OS.IOS;
};
