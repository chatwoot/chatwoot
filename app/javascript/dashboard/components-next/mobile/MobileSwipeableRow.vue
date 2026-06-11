<script setup>
import { ref, inject, watch, computed } from 'vue';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { vHapticTap } from './hapticTap';

const props = defineProps({
  rowId: {
    type: [String, Number],
    required: true,
  },
  actions: {
    type: Array,
    default: () => [],
  },
  leftActions: {
    type: Array,
    default: () => [],
  },
  threshold: {
    type: Number,
    default: 80,
  },
});

const emit = defineEmits(['action', 'leftAction']);

const { medium } = useHaptics();

const openRowId = inject('swipeOpenRowId', ref(null));

const offsetX = ref(0);
const isAnimating = ref(false);
let startX = 0;
let startY = 0;
let isTracking = false;
let directionLocked = false;
let isHorizontal = false;
let hapticFired = false;
let swipeDirection = null; // 'left' or 'right'

const rightActionsWidth = computed(() => props.actions.length * 72);
const leftActionsWidth = computed(() => props.leftActions.length * 72);

const clampedOffset = computed(() =>
  Math.max(
    -rightActionsWidth.value,
    Math.min(leftActionsWidth.value, offsetX.value)
  )
);

const areRightActionsHidden = computed(() => clampedOffset.value >= 0);
const areLeftActionsHidden = computed(() => clampedOffset.value <= 0);

const openSide = computed(() => {
  if (openRowId.value === `${props.rowId}-right`) return 'right';
  if (openRowId.value === `${props.rowId}-left`) return 'left';
  return null;
});

watch(
  () => openRowId.value,
  newId => {
    const isThisRow =
      newId === `${props.rowId}-right` || newId === `${props.rowId}-left`;
    if (!isThisRow && offsetX.value !== 0) {
      isAnimating.value = true;
      offsetX.value = 0;
    }
  }
);

const onTouchStart = event => {
  if (isAnimating.value) return;
  const touch = event.touches[0];
  startX = touch.clientX;
  startY = touch.clientY;
  isTracking = true;
  directionLocked = false;
  isHorizontal = false;
  hapticFired = false;
  swipeDirection = null;
  isAnimating.value = false;
};

const onTouchMove = event => {
  if (!isTracking) return;

  const touch = event.touches[0];
  const deltaX = touch.clientX - startX;
  const deltaY = touch.clientY - startY;

  if (!directionLocked) {
    if (Math.abs(deltaX) > 8 || Math.abs(deltaY) > 8) {
      directionLocked = true;
      isHorizontal = Math.abs(deltaX) > Math.abs(deltaY) * 1.5;
    }
    if (!directionLocked) return;
  }

  if (!isHorizontal) {
    isTracking = false;
    return;
  }

  let base = 0;
  if (openSide.value === 'right') base = -rightActionsWidth.value;
  else if (openSide.value === 'left') base = leftActionsWidth.value;

  const raw = base + deltaX;

  // Determine swipe direction based on raw movement
  if (raw < 0 && props.actions.length > 0) {
    swipeDirection = 'left';
  } else if (raw > 0 && props.leftActions.length > 0) {
    swipeDirection = 'right';
  }

  offsetX.value = raw;

  if (!hapticFired && Math.abs(offsetX.value) >= props.threshold) {
    medium();
    hapticFired = true;
  }
};

const onTouchEnd = () => {
  if (!isTracking || !isHorizontal) {
    isTracking = false;
    return;
  }
  isTracking = false;
  isAnimating.value = true;

  if (swipeDirection === 'left' && offsetX.value < -props.threshold) {
    offsetX.value = -rightActionsWidth.value;
    openRowId.value = `${props.rowId}-right`;
  } else if (swipeDirection === 'right' && offsetX.value > props.threshold) {
    offsetX.value = leftActionsWidth.value;
    openRowId.value = `${props.rowId}-left`;
  } else {
    offsetX.value = 0;
    if (openSide.value) {
      openRowId.value = null;
    }
  }
};

const onTransitionEnd = () => {
  isAnimating.value = false;
};

const onRightActionClick = actionKey => {
  emit('action', actionKey);
  isAnimating.value = true;
  offsetX.value = 0;
  openRowId.value = null;
};

const onLeftActionClick = actionKey => {
  emit('leftAction', actionKey);
  isAnimating.value = true;
  offsetX.value = 0;
  openRowId.value = null;
};
</script>

<template>
  <div class="relative overflow-hidden rounded-lg">
    <!-- Left action buttons (revealed on swipe right) -->
    <div
      v-if="leftActions.length"
      class="absolute inset-y-0 left-0 flex items-stretch"
      :class="{ 'pointer-events-none': areLeftActionsHidden }"
      :style="{ width: `${leftActionsWidth}px` }"
      :inert="areLeftActionsHidden"
    >
      <button
        v-for="action in leftActions"
        :key="action.key"
        v-haptic-tap
        class="flex flex-col items-center justify-center w-[72px] text-white text-xs font-medium gap-1"
        :class="action.color"
        :tabindex="areLeftActionsHidden ? -1 : 0"
        @click.stop="onLeftActionClick(action.key)"
      >
        <span class="size-5" :class="action.icon" />
        <span>{{ action.label }}</span>
      </button>
    </div>
    <!-- Right action buttons (revealed on swipe left) -->
    <div
      v-if="actions.length"
      class="absolute inset-y-0 right-0 flex items-stretch"
      :class="{ 'pointer-events-none': areRightActionsHidden }"
      :style="{ width: `${rightActionsWidth}px` }"
      :inert="areRightActionsHidden"
    >
      <button
        v-for="action in actions"
        :key="action.key"
        v-haptic-tap
        class="flex flex-col items-center justify-center w-[72px] text-white text-xs font-medium gap-1"
        :class="action.color"
        :tabindex="areRightActionsHidden ? -1 : 0"
        @click.stop="onRightActionClick(action.key)"
      >
        <span class="size-5" :class="action.icon" />
        <span>{{ action.label }}</span>
      </button>
    </div>
    <!-- Swipeable content -->
    <div
      :style="{ transform: `translateX(${clampedOffset}px)` }"
      :class="{ 'transition-transform duration-200 ease-out': isAnimating }"
      class="relative z-10 bg-white dark:bg-n-background"
      @touchstart.passive="onTouchStart"
      @touchmove.passive="onTouchMove"
      @touchend="onTouchEnd"
      @transitionend="onTransitionEnd"
    >
      <slot />
    </div>
  </div>
</template>
