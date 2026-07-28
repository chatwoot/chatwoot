import {
  isEnter,
  isEscape,
  hasPressedShift,
  hasPressedCommand,
  hasPressedMod,
  hasPressedCommandAndEnter,
  hasPressedEnterAndNotCmdOrShift,
  isActiveElementTypeable,
} from '../KeyboardHelpers';

const setNavigator = navigatorValue => {
  Object.defineProperty(global, 'navigator', {
    value: navigatorValue,
    configurable: true,
    writable: true,
  });
};

const onMac = () => setNavigator({ userAgentData: { platform: 'macOS' } });
const onWindows = () =>
  setNavigator({ userAgentData: { platform: 'Windows' } });
const onIOS = () =>
  setNavigator({
    userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
  });

describe('#KeyboardHelpers', () => {
  describe('#isEnter', () => {
    it('return correct values', () => {
      expect(isEnter({ key: 'Enter' })).toEqual(true);
    });
  });

  describe('#isEscape', () => {
    it('return correct values', () => {
      expect(isEscape({ key: 'Escape' })).toEqual(true);
    });
  });

  describe('#hasPressedShift', () => {
    it('return correct values', () => {
      expect(hasPressedShift({ shiftKey: true })).toEqual(true);
    });
  });

  describe('#hasPressedCommand', () => {
    it('return correct values', () => {
      expect(hasPressedCommand({ metaKey: true })).toEqual(true);
    });
  });

  describe('#hasPressedMod', () => {
    const originalNavigator = global.navigator;

    afterEach(() => {
      setNavigator(originalNavigator);
    });

    it('uses metaKey on macOS', () => {
      onMac();
      expect(hasPressedMod({ metaKey: true, ctrlKey: false })).toBe(true);
      expect(hasPressedMod({ metaKey: false, ctrlKey: true })).toBe(false);
    });

    it('uses ctrlKey on Windows', () => {
      onWindows();
      expect(hasPressedMod({ metaKey: false, ctrlKey: true })).toBe(true);
      expect(hasPressedMod({ metaKey: true, ctrlKey: false })).toBe(false);
    });

    it('uses metaKey on iOS hardware keyboards', () => {
      onIOS();
      expect(hasPressedMod({ metaKey: true, ctrlKey: false })).toBe(true);
      expect(hasPressedMod({ metaKey: false, ctrlKey: true })).toBe(false);
    });

    it('returns false when no modifier is held', () => {
      onWindows();
      expect(hasPressedMod({ metaKey: false, ctrlKey: false })).toBe(false);
    });
  });

  describe('#hasPressedCommandAndEnter', () => {
    const originalNavigator = global.navigator;

    afterEach(() => {
      setNavigator(originalNavigator);
    });

    it('returns true for Cmd+Enter on macOS', () => {
      onMac();
      expect(hasPressedCommandAndEnter({ key: 'Enter', metaKey: true })).toBe(
        true
      );
    });

    it('returns true for Ctrl+Enter on Windows (CW-6859 fix)', () => {
      onWindows();
      expect(hasPressedCommandAndEnter({ key: 'Enter', ctrlKey: true })).toBe(
        true
      );
    });

    it('returns false for Ctrl+Enter on macOS (Mac uses Cmd, not Ctrl)', () => {
      onMac();
      expect(hasPressedCommandAndEnter({ key: 'Enter', ctrlKey: true })).toBe(
        false
      );
    });

    it('returns true for Cmd+Enter on iOS hardware keyboards', () => {
      onIOS();
      expect(hasPressedCommandAndEnter({ key: 'Enter', metaKey: true })).toBe(
        true
      );
    });

    it('returns false for plain Enter', () => {
      onWindows();
      expect(hasPressedCommandAndEnter({ key: 'Enter' })).toBe(false);
    });
  });

  describe('#hasPressedEnterAndNotCmdOrShift', () => {
    const originalNavigator = global.navigator;

    afterEach(() => {
      setNavigator(originalNavigator);
    });

    it('returns true for plain Enter on Windows', () => {
      onWindows();
      expect(hasPressedEnterAndNotCmdOrShift({ key: 'Enter' })).toBe(true);
    });

    it('returns false for Ctrl+Enter on Windows (mod is held)', () => {
      onWindows();
      expect(
        hasPressedEnterAndNotCmdOrShift({ key: 'Enter', ctrlKey: true })
      ).toBe(false);
    });

    it('returns false for Cmd+Enter on macOS (mod is held)', () => {
      onMac();
      expect(
        hasPressedEnterAndNotCmdOrShift({ key: 'Enter', metaKey: true })
      ).toBe(false);
    });

    it('returns false for Shift+Enter', () => {
      onWindows();
      expect(
        hasPressedEnterAndNotCmdOrShift({ key: 'Enter', shiftKey: true })
      ).toBe(false);
    });
  });
});

describe('isActiveElementTypeable', () => {
  it('should return true if the active element is an input element', () => {
    const event = { target: document.createElement('input') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return true if the active element is a textarea element', () => {
    const event = { target: document.createElement('textarea') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return true if the active element is a contentEditable element', () => {
    const element = document.createElement('div');
    element.contentEditable = 'true';
    const event = { target: element };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(true);
  });

  it('should return false if the active element is not typeable', () => {
    const event = { target: document.createElement('div') };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(false);
  });

  it('should return false if the active element is null', () => {
    const event = { target: null };
    const result = isActiveElementTypeable(event);
    expect(result).toBe(false);
  });
});
