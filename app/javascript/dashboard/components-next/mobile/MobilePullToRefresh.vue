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

const emit = defineEmits(['refresh']);

const isRefreshing = ref(false);
const pullDistance = ref(0);
const isPulling = ref(false);
const pullRootRef = ref(null);

const { medium } = useHaptics();

const MAX_PULL_DISTANCE = 96;
const PULL_THRESHOLD = 72;
const MIN_REFRESH_DURATION = 550;
let startY = 0;
let startX = 0;
let thresholdTriggered = false;
let directionLocked = false;
let isVerticalGesture = false;

const pullProgress = computed(() => {
  return Math.min(pullDistance.value / PULL_THRESHOLD, 1);
});

const indicatorHeight = computed(() => {
  if (isRefreshing.value) return 52;
  return pullDistance.value;
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

const resetPullState = () => {
  isPulling.value = false;
  pullDistance.value = 0;
  thresholdTriggered = false;
  directionLocked = false;
  isVerticalGesture = false;
};

const onTouchStart = event => {
  if (isRefreshing.value || !isAtTop()) return;

  const touch = event.touches[0];
  startY = touch.clientY;
  startX = touch.clientX;
  isPulling.value = true;
  thresholdTriggered = false;
  directionLocked = false;
  isVerticalGesture = false;
};

const onTouchMove = event => {
  if (!isPulling.value) return;

  const touch = event.touches[0];
  const deltaY = touch.clientY - startY;
  const deltaX = touch.clientX - startX;

  if (!directionLocked && (Math.abs(deltaY) > 6 || Math.abs(deltaX) > 6)) {
    directionLocked = true;
    isVerticalGesture = deltaY > 0 && Math.abs(deltaY) > Math.abs(deltaX) * 1.1;
    if (!isVerticalGesture) {
      resetPullState();
      return;
    }
  }

  if (!isVerticalGesture) return;

  if (deltaY <= 0 || !isAtTop()) {
    pullDistance.value = 0;
    thresholdTriggered = false;
    return;
  }

  pullDistance.value = Math.min(deltaY * 0.42, MAX_PULL_DISTANCE);

  if (!thresholdTriggered && pullDistance.value >= PULL_THRESHOLD) {
    medium();
    thresholdTriggered = true;
  } else if (thresholdTriggered && pullDistance.value < PULL_THRESHOLD) {
    thresholdTriggered = false;
  }
};

const triggerRefresh = async () => {
  isRefreshing.value = true;

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
  }
};

const onTouchEnd = async () => {
  if (!isPulling.value) return;

  isPulling.value = false;
  directionLocked = false;
  isVerticalGesture = false;

  const shouldRefresh = pullDistance.value >= PULL_THRESHOLD;
  thresholdTriggered = false;

  if (shouldRefresh) {
    pullDistance.value = PULL_THRESHOLD;
    await triggerRefresh();
  }

  pullDistance.value = 0;
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
      v-if="pullDistance > 2 || isRefreshing"
      class="pointer-events-none flex items-center justify-center overflow-hidden transition-all duration-200"
      :style="{ height: `${indicatorHeight}px` }"
    >
      <MobilePetalLoader :progress="pullProgress" :spinning="isRefreshing" />
    </div>
    <slot />
  </div>
</template>
