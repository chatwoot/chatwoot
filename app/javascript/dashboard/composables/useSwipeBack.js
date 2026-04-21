import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useHaptics } from './useHaptics';

const EDGE_ZONE = 20;
const BACK_THRESHOLD = 100;

export const useSwipeBack = (elementRef, onBack) => {
  const swipeOffset = ref(0);
  const isSwiping = ref(false);

  const { light } = useHaptics();

  let startX = 0;
  let startY = 0;
  let tracking = false;
  let locked = false;
  let isHorizontal = false;

  const isRtl = () => document.documentElement.getAttribute('dir') === 'rtl';

  const isEdgeTouch = clientX => {
    if (isRtl()) {
      return clientX >= window.innerWidth - EDGE_ZONE;
    }
    return clientX <= EDGE_ZONE;
  };

  const onTouchStart = event => {
    const touch = event.touches[0];
    if (!isEdgeTouch(touch.clientX)) return;
    startX = touch.clientX;
    startY = touch.clientY;
    tracking = true;
    locked = false;
    isHorizontal = false;
  };

  const onTouchMove = event => {
    if (!tracking) return;
    const touch = event.touches[0];
    const deltaX = touch.clientX - startX;
    const deltaY = touch.clientY - startY;

    if (!locked) {
      if (Math.abs(deltaX) > 8 || Math.abs(deltaY) > 8) {
        locked = true;
        isHorizontal = Math.abs(deltaX) > Math.abs(deltaY);
      }
      if (!locked) return;
    }

    if (!isHorizontal) {
      tracking = false;
      return;
    }

    const rtl = isRtl();
    const offset = rtl ? -deltaX : deltaX;
    if (offset > 0) {
      isSwiping.value = true;
      swipeOffset.value = Math.min(offset * 0.6, window.innerWidth * 0.8);
    }
  };

  const onTouchEnd = () => {
    if (!tracking || !isHorizontal) {
      tracking = false;
      return;
    }
    tracking = false;

    if (swipeOffset.value >= BACK_THRESHOLD) {
      light();
      swipeOffset.value = window.innerWidth;
      setTimeout(() => {
        onBack();
        swipeOffset.value = 0;
        isSwiping.value = false;
      }, 200);
    } else {
      swipeOffset.value = 0;
      isSwiping.value = false;
    }
  };

  onMounted(() => {
    const el = elementRef.value;
    if (!el) return;
    el.addEventListener('touchstart', onTouchStart, { passive: true });
    el.addEventListener('touchmove', onTouchMove, { passive: true });
    el.addEventListener('touchend', onTouchEnd);
  });

  onUnmounted(() => {
    const el = elementRef.value;
    if (!el) return;
    el.removeEventListener('touchstart', onTouchStart);
    el.removeEventListener('touchmove', onTouchMove);
    el.removeEventListener('touchend', onTouchEnd);
  });

  const swipeProgress = computed(() => {
    if (!isSwiping.value || swipeOffset.value <= 0) return 0;
    return Math.min(swipeOffset.value / window.innerWidth, 1);
  });

  return { swipeOffset, isSwiping, swipeProgress };
};
