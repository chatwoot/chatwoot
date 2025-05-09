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

export function useTargetScrollLock(defaultTarget) {
  const scrollLockInstance = shallowRef(null);
  const isLocked = ref(false);

  function resolveTarget(target) {
    if (!target) return null;
    if (typeof target === 'string') return document.querySelector(target); // class, id, etc
    if (target instanceof HTMLElement) return target; // DOM element
    return unref(target); // ref
  }

  function unlockScroll() {
    if (!scrollLockInstance.value) return false;

    scrollLockInstance.value.value = false;
    isLocked.value = false;
    scrollLockInstance.value = null;
    return true;
  }

  function lockScroll(target = defaultTarget) {
    unlockScroll(); // Always unlock first
    const el = resolveTarget(target);
    if (!el) return false;

    scrollLockInstance.value = useScrollLock(el, true);
    isLocked.value = true;
    return true;
  }

  onUnmounted(() => {
    unlockScroll();
  });

  return { lockScroll, unlockScroll, isLocked };
}
