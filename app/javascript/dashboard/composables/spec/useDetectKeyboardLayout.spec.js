import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import {
  LAYOUT_QWERTY,
  LAYOUT_QWERTZ,
  LAYOUT_AZERTY,
} from 'shared/helpers/KeyboardHelpers';

describe('useDetectKeyboardLayout', () => {
  beforeEach(() => {
    window.cw_keyboard_layout = null;
  });

  it('returns cached layout if available', async () => {
    window.cw_keyboard_layout = LAYOUT_QWERTY;
    const layout = await useDetectKeyboardLayout();
    expect(layout).toBe(LAYOUT_QWERTY);
  });

  it('should detect QWERTY layout using modern method', async () => {
    navigator.keyboard = {
      getLayoutMap: vi.fn().mockResolvedValue(
        new Map([
          ['KeyQ', 'q'],
          ['KeyW', 'w'],
          ['KeyE', 'e'],
          ['KeyR', 'r'],
          ['KeyT', 't'],
          ['KeyY', 'y'],
        ])
      ),
    };

    const layout = await useDetectKeyboardLayout();
    expect(layout).toBe(LAYOUT_QWERTY);
  });

  it('should detect QWERTZ layout using modern method', async () => {
    navigator.keyboard = {
      getLayoutMap: vi.fn().mockResolvedValue(
        new Map([
          ['KeyQ', 'q'],
          ['KeyW', 'w'],
          ['KeyE', 'e'],
          ['KeyR', 'r'],
          ['KeyT', 't'],
          ['KeyY', 'z'],
        ])
      ),
    };

    const layout = await useDetectKeyboardLayout();
    expect(layout).toBe(LAYOUT_QWERTZ);
  });

  it('should detect AZERTY layout using modern method', async () => {
    navigator.keyboard = {
      getLayoutMap: vi.fn().mockResolvedValue(
        new Map([
          ['KeyQ', 'a'],
          ['KeyW', 'z'],
          ['KeyE', 'e'],
          ['KeyR', 'r'],
          ['KeyT', 't'],
          ['KeyY', 'y'],
        ])
      ),
    };

    const layout = await useDetectKeyboardLayout();
    expect(layout).toBe(LAYOUT_AZERTY);
  });

  it('should use legacy method if navigator.keyboard is not available', async () => {
    navigator.keyboard = undefined;

    const layout = await useDetectKeyboardLayout();
    expect([LAYOUT_QWERTY, LAYOUT_QWERTZ, LAYOUT_AZERTY]).toContain(layout);
  });

  it('should cache the detected layout', async () => {
    navigator.keyboard = {
      getLayoutMap: vi.fn().mockResolvedValue(
        new Map([
          ['KeyQ', 'q'],
          ['KeyW', 'w'],
          ['KeyE', 'e'],
          ['KeyR', 'r'],
          ['KeyT', 't'],
          ['KeyY', 'y'],
        ])
      ),
    };

    const layout = await useDetectKeyboardLayout();
    expect(layout).toBe(LAYOUT_QWERTY);

    const layoutAgain = await useDetectKeyboardLayout();
    expect(layoutAgain).toBe(LAYOUT_QWERTY);
    expect(navigator.keyboard.getLayoutMap).toHaveBeenCalledTimes(1);
  });
});
