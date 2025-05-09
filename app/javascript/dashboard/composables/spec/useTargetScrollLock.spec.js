import { ref } from 'vue';
import { useTargetScrollLock } from '../useTargetScrollLock';
import { useScrollLock } from '@vueuse/core';
import { describe, beforeEach, test, expect, vi } from 'vitest';

vi.mock('@vueuse/core', () => ({
  useScrollLock: vi.fn(),
}));

vi.mock('vue', async () => {
  const actual = await vi.importActual('vue');
  return {
    ...actual,
    onUnmounted: vi.fn(fn => {
      vi.fn.unmountCallback = fn;
    }),
  };
});

describe('useTargetScrollLock', () => {
  let mockLockRef;

  beforeEach(() => {
    document.body.innerHTML = `
      <div class="conversation-panel"></div>
      <div id="modal"></div>
    `;

    mockLockRef = ref(true);
    useScrollLock.mockReturnValue(mockLockRef);

    vi.clearAllMocks();
  });

  test('provides the expected API', () => {
    const api = useTargetScrollLock();

    expect(api).toHaveProperty('lockScroll');
    expect(api).toHaveProperty('unlockScroll');
    expect(api).toHaveProperty('isLocked');
    expect(api.isLocked.value).toBe(false);
  });

  test('handles various target types', () => {
    const { lockScroll } = useTargetScrollLock();

    lockScroll('.conversation-panel');
    expect(useScrollLock).toHaveBeenLastCalledWith(
      document.querySelector('.conversation-panel'),
      true
    );

    const element = document.querySelector('#modal');
    lockScroll(element);
    expect(useScrollLock).toHaveBeenLastCalledWith(element, true);

    const elementRef = ref(element);
    lockScroll(elementRef);
    expect(useScrollLock).toHaveBeenLastCalledWith(element, true);
  });

  test('handles default target parameter', () => {
    const defaultEl = document.querySelector('.conversation-panel');
    const { lockScroll } = useTargetScrollLock(defaultEl);

    lockScroll();
    expect(useScrollLock).toHaveBeenCalledWith(defaultEl, true);
  });

  test('fails gracefully with invalid targets', () => {
    const { lockScroll, isLocked } = useTargetScrollLock();

    expect(lockScroll('.doesnt-exist')).toBe(false);
    expect(isLocked.value).toBe(false);

    expect(lockScroll(null)).toBe(false);
    expect(isLocked.value).toBe(false);

    expect(useScrollLock).not.toHaveBeenCalled();
  });

  test('manages lock state correctly', () => {
    const { lockScroll, unlockScroll, isLocked } = useTargetScrollLock();

    expect(isLocked.value).toBe(false);

    lockScroll('.conversation-panel');
    expect(isLocked.value).toBe(true);
    unlockScroll();
    expect(isLocked.value).toBe(false);
    expect(mockLockRef.value).toBe(false);
  });

  test('handles lock switching correctly', () => {
    const { lockScroll } = useTargetScrollLock();

    lockScroll('.conversation-panel');
    lockScroll('#modal');

    expect(mockLockRef.value).toBe(false);
    expect(useScrollLock).toHaveBeenCalledTimes(2);
  });

  test('cleans up on component unmount', () => {
    const { lockScroll, isLocked } = useTargetScrollLock();

    lockScroll('.conversation-panel');
    expect(isLocked.value).toBe(true);

    if (vi.fn.unmountCallback) {
      vi.fn.unmountCallback();
    }

    expect(isLocked.value).toBe(false);
  });
});
