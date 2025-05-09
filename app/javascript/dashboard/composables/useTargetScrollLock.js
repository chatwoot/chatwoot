/**
 * useTargetScrollLock composable
 *
 * Usage:
 *   const { lockScroll, unlockScroll, isLocked } = useTargetScrollLock(target);
 *   target can be a ref, DOM element, or selector string (class, id, etc)
 *   eg: lockScroll('.conversation-panel'); unlockScroll();
 */

import { ref, unref, shallowRef, onUnmounted } from 'vue';
import { useScrollLock } from '@vueuse/core';

const getTargetElement = target => {
  if (!target) return null;
  if (typeof target === 'string') return document.querySelector(target);
  if (target instanceof HTMLElement) return target;
  return unref(target);
};

export const useTargetScrollLock = defaultTarget => {
  const scrollLockInstance = shallowRef(null);
  const isLocked = ref(false);

  // Simplified unlock function
  const unlockScroll = () => {
    if (!scrollLockInstance.value) return false;

    scrollLockInstance.value.value = false;
    isLocked.value = false;
    scrollLockInstance.value = null;
    return true;
  };

  // Simplified lock function
  const lockScroll = (target = defaultTarget) => {
    unlockScroll();

    const el = getTargetElement(target);
    if (!el) return false;

    scrollLockInstance.value = useScrollLock(el, true);
    isLocked.value = true;
    return true;
  };

  // Auto-cleanup
  onUnmounted(unlockScroll);

  return { lockScroll, unlockScroll, isLocked };
};
