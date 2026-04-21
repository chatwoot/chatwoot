import { detectOS, isApple, OS } from '../platform';

const setNavigator = ({ userAgentData, userAgent, maxTouchPoints } = {}) => {
  Object.defineProperty(global, 'navigator', {
    value: { userAgentData, userAgent, maxTouchPoints },
    configurable: true,
    writable: true,
  });
};

describe('detectOS', () => {
  const originalNavigator = global.navigator;

  afterEach(() => {
    Object.defineProperty(global, 'navigator', {
      value: originalNavigator,
      configurable: true,
      writable: true,
    });
  });

  describe('with userAgentData available', () => {
    it('returns OS.MAC for macOS', () => {
      setNavigator({ userAgentData: { platform: 'macOS' } });
      expect(detectOS()).toBe(OS.MAC);
    });

    it('returns OS.WINDOWS for Windows', () => {
      setNavigator({ userAgentData: { platform: 'Windows' } });
      expect(detectOS()).toBe(OS.WINDOWS);
    });

    it('returns OS.LINUX for Linux', () => {
      setNavigator({ userAgentData: { platform: 'Linux' } });
      expect(detectOS()).toBe(OS.LINUX);
    });

    it('returns OS.ANDROID for Android', () => {
      setNavigator({ userAgentData: { platform: 'Android' } });
      expect(detectOS()).toBe(OS.ANDROID);
    });

    it('falls through to userAgent for unmapped values like "Chrome OS"', () => {
      setNavigator({
        userAgentData: { platform: 'Chrome OS' },
        userAgent: 'Mozilla/5.0 (X11; CrOS x86_64) AppleWebKit/537.36',
      });
      // Not a mapped UAD value AND not a recognized UA pattern → unknown
      expect(detectOS()).toBe(OS.UNKNOWN);
    });

    it('prefers userAgentData over userAgent when value is mapped', () => {
      setNavigator({
        userAgentData: { platform: 'Windows' },
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
      });
      expect(detectOS()).toBe(OS.WINDOWS);
    });
  });

  describe('with userAgent fallback', () => {
    it('detects macOS from Safari userAgent', () => {
      setNavigator({
        userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
      });
      expect(detectOS()).toBe(OS.MAC);
    });

    it('detects Windows from userAgent', () => {
      setNavigator({
        userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });
      expect(detectOS()).toBe(OS.WINDOWS);
    });

    it('detects Linux from userAgent', () => {
      setNavigator({
        userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
      });
      expect(detectOS()).toBe(OS.LINUX);
    });

    it('detects Android from userAgent (before Linux match)', () => {
      setNavigator({
        userAgent:
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
      });
      expect(detectOS()).toBe(OS.ANDROID);
    });

    it('detects iOS from iPhone userAgent', () => {
      setNavigator({
        userAgent:
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
      });
      expect(detectOS()).toBe(OS.IOS);
    });

    it('detects iPadOS spoofing Macintosh via maxTouchPoints', () => {
      setNavigator({
        userAgent:
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
        maxTouchPoints: 5,
      });
      expect(detectOS()).toBe(OS.IOS);
    });

    it('returns OS.UNKNOWN when no match', () => {
      setNavigator({ userAgent: 'SomeRandomBot/1.0' });
      expect(detectOS()).toBe(OS.UNKNOWN);
    });

    it('returns OS.UNKNOWN when userAgent is missing', () => {
      setNavigator({});
      expect(detectOS()).toBe(OS.UNKNOWN);
    });
  });

  describe('without navigator', () => {
    it('returns OS.UNKNOWN when navigator is undefined', () => {
      Object.defineProperty(global, 'navigator', {
        value: undefined,
        configurable: true,
        writable: true,
      });
      expect(detectOS()).toBe(OS.UNKNOWN);
    });
  });
});

describe('isApple', () => {
  const originalNavigator = global.navigator;

  afterEach(() => {
    Object.defineProperty(global, 'navigator', {
      value: originalNavigator,
      configurable: true,
      writable: true,
    });
  });

  it('returns true on macOS', () => {
    setNavigator({ userAgentData: { platform: 'macOS' } });
    expect(isApple()).toBe(true);
  });

  it('returns true on iOS (iPhone)', () => {
    setNavigator({
      userAgent:
        'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
    });
    expect(isApple()).toBe(true);
  });

  it('returns true on iPadOS spoofing Macintosh', () => {
    setNavigator({
      userAgent:
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15',
      maxTouchPoints: 5,
    });
    expect(isApple()).toBe(true);
  });

  it('returns false on Windows', () => {
    setNavigator({ userAgentData: { platform: 'Windows' } });
    expect(isApple()).toBe(false);
  });

  it('returns false on Linux', () => {
    setNavigator({ userAgentData: { platform: 'Linux' } });
    expect(isApple()).toBe(false);
  });

  it('returns false on Android', () => {
    setNavigator({ userAgentData: { platform: 'Android' } });
    expect(isApple()).toBe(false);
  });
});

describe('OS constants', () => {
  it('is frozen so callers cannot mutate it', () => {
    expect(Object.isFrozen(OS)).toBe(true);
  });
});
