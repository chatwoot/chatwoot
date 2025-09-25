import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { WindowVisibilityHelper } from '../WindowVisibilityHelper';

describe('WindowVisibilityHelper', () => {
  let blurCallback;
  let focusCallback;
  let windowEventListeners;
  let documentHiddenValue = false;

  beforeEach(() => {
    vi.resetModules();
    vi.resetAllMocks();

    // Reset event listeners before each test
    windowEventListeners = {};

    // Mock window.addEventListener
    window.addEventListener = vi.fn((event, callback) => {
      windowEventListeners[event] = callback;
      if (event === 'blur') blurCallback = callback;
      if (event === 'focus') focusCallback = callback;
    });

    // Mock document.hidden with a getter that returns our controlled value
    Object.defineProperty(document, 'hidden', {
      configurable: true,
      get: () => documentHiddenValue,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    documentHiddenValue = false;
  });

  describe('initialization', () => {
    it('should add blur and focus event listeners', () => {
      const helper = new WindowVisibilityHelper();
      expect(helper.isVisible).toBe(true);

      expect(window.addEventListener).toHaveBeenCalledTimes(2);
      expect(window.addEventListener).toHaveBeenCalledWith(
        'blur',
        expect.any(Function)
      );
      expect(window.addEventListener).toHaveBeenCalledWith(
        'focus',
        expect.any(Function)
      );
    });
  });

  describe('window events', () => {
    it('should set isVisible to false on blur', () => {
      const helper = new WindowVisibilityHelper();
      blurCallback();
      expect(helper.isVisible).toBe(false);
    });

    it('should set isVisible to true on focus', () => {
      const helper = new WindowVisibilityHelper();
      blurCallback(); // First blur the window
      focusCallback(); // Then focus it
      expect(helper.isVisible).toBe(true);
    });

    it('should handle multiple blur/focus events', () => {
      const helper = new WindowVisibilityHelper();

      blurCallback();
      expect(helper.isVisible).toBe(false);

      focusCallback();
      expect(helper.isVisible).toBe(true);

      blurCallback();
      expect(helper.isVisible).toBe(false);
    });
  });

  describe('isWindowVisible', () => {
    it('should return true when document is visible and window is focused', () => {
      const helper = new WindowVisibilityHelper();
      documentHiddenValue = false;
      helper.isVisible = true;

      expect(helper.isWindowVisible()).toBe(true);
    });

    it('should return false when document is hidden', () => {
      const helper = new WindowVisibilityHelper();
      documentHiddenValue = true;
      helper.isVisible = true;

      expect(helper.isWindowVisible()).toBe(false);
    });

    it('should return false when window is not focused', () => {
      const helper = new WindowVisibilityHelper();
      documentHiddenValue = false;
      helper.isVisible = false;

      expect(helper.isWindowVisible()).toBe(false);
    });

    it('should return false when both document is hidden and window is not focused', () => {
      const helper = new WindowVisibilityHelper();
      documentHiddenValue = true;
      helper.isVisible = false;

      expect(helper.isWindowVisible()).toBe(false);
    });
  });
});
