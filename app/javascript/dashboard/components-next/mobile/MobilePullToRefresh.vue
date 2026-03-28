<script setup>
import { computed, ref } from 'vue';
import { useHaptics } from 'dashboard/composables/useHaptics';
import MobilePetalLoader from './MobilePetalLoader.vue';

const props = defineProps({
  refreshAction: {
    type: Function,
    default: null,
  },
});

const emit = defineEmits(['refresh', 'refreshStart', 'refreshEnd']);

const isRefreshing = ref(false);
const isPulling = ref(false);
const isArmed = ref(false);
const pullDistance = ref(0);
const pullRootRef = ref(null);

const { medium } = useHaptics();

const MAX_PULL_DISTANCE = 132;
const PULL_THRESHOLD = 104;
const REFRESH_HOLD_DISTANCE = 56;
const RESISTANCE_DISTANCE = 140;
const MIN_ARM_DURATION = 140;
const MIN_REFRESH_DURATION = 550;
const DIRECTION_LOCK_DISTANCE = 8;

let startY = 0;
let startX = 0;
let gestureStartedAt = 0;
let directionLocked = false;
let isVerticalGesture = false;

const now = () => {
  return typeof performance !== 'undefined' ? performance.now() : Date.now();
};

const armProgress = computed(() => {
  return Math.min(pullDistance.value / PULL_THRESHOLD, 1);
});

const visualProgress = computed(() => {
  if (isArmed.value || isRefreshing.value) return 1;
  return armProgress.value;
});

const isIndicatorVisible = computed(() => {
  return pullDistance.value > 0 || isRefreshing.value;
});

const contentOffset = computed(() => {
  if (isRefreshing.value) return REFRESH_HOLD_DISTANCE;
  return pullDistance.value;
});

const indicatorStyle = computed(() => {
  const translateY = Math.min(contentOffset.value * 0.42, 24);
  const opacity = isRefreshing.value
    ? 1
    : Math.min(0.16 + armProgress.value * 0.9, 1);

  return {
    opacity,
    transform: `translate3d(0, ${translateY}px, 0)`,
  };
});

const contentStyle = computed(() => {
  return {
    transform: `translate3d(0, ${contentOffset.value}px, 0)`,
  };
});

const getScrollTarget = () => {
  return (
    pullRootRef.value?.querySelector('[data-mobile-pull-scroll]') ||
    pullRootRef.value
  );
};

const isAtTop = () => {
  const scrollTarget = getScrollTarget();
  return (scrollTarget?.scrollTop || 0) <= 0;
};

const applyResistance = deltaY => {
  if (deltaY <= 0) return 0;

  return Math.min(
    MAX_PULL_DISTANCE * (1 - Math.exp(-deltaY / RESISTANCE_DISTANCE)),
    MAX_PULL_DISTANCE
  );
};

const resetPullState = ({ keepDistance = false } = {}) => {
  isPulling.value = false;
  isArmed.value = false;
  directionLocked = false;
  isVerticalGesture = false;
  gestureStartedAt = 0;

  if (!keepDistance) {
    pullDistance.value = 0;
  }
};

const onTouchStart = event => {
  if (isRefreshing.value || !isAtTop()) return;

  const touch = event.touches[0];
  startY = touch.clientY;
  startX = touch.clientX;
  gestureStartedAt = now();
  isPulling.value = true;
  isArmed.value = false;
  directionLocked = false;
  isVerticalGesture = false;
};

const onTouchMove = event => {
  if (!isPulling.value) return;

  const touch = event.touches[0];
  const deltaY = touch.clientY - startY;
  const deltaX = touch.clientX - startX;

  if (
    !directionLocked &&
    (Math.abs(deltaY) > DIRECTION_LOCK_DISTANCE ||
      Math.abs(deltaX) > DIRECTION_LOCK_DISTANCE)
  ) {
    directionLocked = true;
    isVerticalGesture =
      deltaY > 0 && Math.abs(deltaY) > Math.abs(deltaX) * 1.15;

    if (!isVerticalGesture) {
      resetPullState();
      return;
    }
  }

  if (!isVerticalGesture) return;

  if (deltaY <= 0 || !isAtTop()) {
    pullDistance.value = 0;
    isArmed.value = false;
    return;
  }

  pullDistance.value = applyResistance(deltaY);

  const canArm =
    pullDistance.value >= PULL_THRESHOLD &&
    now() - gestureStartedAt >= MIN_ARM_DURATION;

  if (canArm && !isArmed.value) {
    isArmed.value = true;
    medium();
  } else if (!canArm && isArmed.value) {
    isArmed.value = false;
  }
};

const triggerRefresh = async () => {
  isRefreshing.value = true;
  emit('refreshStart');

  try {
    const refreshStartedAt = Date.now();

    if (props.refreshAction) {
      await props.refreshAction();
    } else {
      emit('refresh');
      await new Promise(resolve => {
        setTimeout(resolve, 800);
      });
    }

    const remainingDuration =
      MIN_REFRESH_DURATION - (Date.now() - refreshStartedAt);

    if (remainingDuration > 0) {
      await new Promise(resolve => {
        setTimeout(resolve, remainingDuration);
      });
    }
  } finally {
    isRefreshing.value = false;
    isArmed.value = false;
    pullDistance.value = 0;
    emit('refreshEnd');
  }
};

const onTouchEnd = async () => {
  if (!isPulling.value) return;

  const shouldRefresh = isArmed.value;
  resetPullState({ keepDistance: shouldRefresh });

  if (!shouldRefresh) {
    pullDistance.value = 0;
    return;
  }

  pullDistance.value = REFRESH_HOLD_DISTANCE;
  await triggerRefresh();
};

const onTouchCancel = () => {
  if (!isRefreshing.value) {
    resetPullState();
  }
};
</script>

<template>
  <div
    ref="pullRootRef"
    class="relative flex flex-1 flex-col overflow-hidden"
    @touchstart.passive="onTouchStart"
    @touchmove.passive="onTouchMove"
    @touchend="onTouchEnd"
    @touchcancel="onTouchCancel"
  >
    <div
      v-if="isIndicatorVisible"
      class="pointer-events-none absolute inset-x-0 top-0 z-10 flex justify-center"
      :style="indicatorStyle"
    >
      <MobilePetalLoader
        :progress="visualProgress"
        :spinning="isArmed || isRefreshing"
      />
    </div>

    <div
      class="flex min-h-0 flex-1 flex-col will-change-transform"
      :class="
        isPulling
          ? 'transition-none'
          : 'transition-transform duration-200 ease-[cubic-bezier(0.22,1,0.36,1)]'
      "
      :style="contentStyle"
    >
      <slot />
    </div>
  </div>
</template>
