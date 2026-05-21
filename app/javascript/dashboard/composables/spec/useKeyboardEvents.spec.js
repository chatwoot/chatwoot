const keyboardEventsMock = vi.hoisted(() => ({
  mountedCallbacks: [],
  unmountedCallbacks: [],
  registeredKeybindings: {},
}));

vi.mock('vue', async importOriginal => ({
  ...(await importOriginal()),
  onMounted: vi.fn(callback =>
    keyboardEventsMock.mountedCallbacks.push(callback)
  ),
  onUnmounted: vi.fn(callback =>
    keyboardEventsMock.unmountedCallbacks.push(callback)
  ),
}));

vi.mock('dashboard/composables/useDetectKeyboardLayout', () => ({
  useDetectKeyboardLayout: vi.fn(() => Promise.resolve('QWERTY')),
}));

vi.mock('tinykeys', () => ({
  createKeybindingsHandler: vi.fn(keybindings => {
    keyboardEventsMock.registeredKeybindings = keybindings;
    return event => keybindings[event.shortcut]?.(event);
  }),
}));

import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

describe('useKeyboardEvents', () => {
  beforeEach(() => {
    keyboardEventsMock.mountedCallbacks = [];
    keyboardEventsMock.unmountedCallbacks = [];
    keyboardEventsMock.registeredKeybindings = {};
  });

  it('should be defined', () => {
    expect(useKeyboardEvents).toBeDefined();
  });

  it('should return a function', () => {
    expect(useKeyboardEvents).toBeInstanceOf(Function);
  });

  it('should set up listeners on mount and remove them on unmount', async () => {
    const events = {
      'ALT+KeyL': () => {},
    };

    useKeyboardEvents(events);
    await keyboardEventsMock.mountedCallbacks[0]();
    keyboardEventsMock.unmountedCallbacks[0]();

    expect(Object.keys(keyboardEventsMock.registeredKeybindings)).toEqual([
      'ALT+KeyL',
    ]);
  });

  it('ignores shortcuts on focused typeable elements by default', async () => {
    const action = vi.fn();
    const textarea = document.createElement('textarea');

    useKeyboardEvents({
      'Alt+KeyL': {
        action,
        allowOnFocusedInput: false,
      },
    });
    await keyboardEventsMock.mountedCallbacks[0]();
    keyboardEventsMock.registeredKeybindings['Alt+KeyL']({
      target: textarea,
      key: 'l',
    });

    expect(action).not.toHaveBeenCalled();
  });

  it('runs shortcuts on focused typeable elements when allowed', async () => {
    const action = vi.fn();
    const textarea = document.createElement('textarea');

    useKeyboardEvents({
      'Alt+KeyL': {
        action,
        allowOnFocusedInput: true,
      },
    });
    await keyboardEventsMock.mountedCallbacks[0]();
    keyboardEventsMock.registeredKeybindings['Alt+KeyL']({
      target: textarea,
      key: 'l',
    });

    expect(action).toHaveBeenCalledTimes(1);
  });
});
