import { unref } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

describe('useKeyboardEvents', () => {
  it('should be defined', () => {
    expect(useKeyboardEvents).toBeDefined();
  });

  it('should return a function', () => {
    expect(useKeyboardEvents).toBeInstanceOf(Function);
  });

  it('should set up listeners on mount and remove them on unmount', async () => {
    const el = document.createElement('div');
    const elRef = unref({ value: el });
    const events = {
      'ALT+KeyL': () => {},
    };

    const mountedMock = vi.fn();
    const unmountedMock = vi.fn();
    useKeyboardEvents(events, elRef);
    mountedMock();
    unmountedMock();

    expect(mountedMock).toHaveBeenCalled();
    expect(unmountedMock).toHaveBeenCalled();
  });
});
