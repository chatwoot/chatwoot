<script setup>
import { ref, inject, watch, computed } from 'vue';
import { useHaptics } from 'dashboard/composables/useHaptics';

const props = defineProps({
  rowId: {
    type: [String, Number],
    required: true,
  },
  actions: {
    type: Array,
    default: () => [],
  },
  threshold: {
    type: Number,
    default: 80,
  },
});

const emit = defineEmits(['action']);

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

const actionsWidth = computed(() => props.actions.length * 72);

const clampedOffset = computed(() =>
  Math.max(-actionsWidth.value, Math.min(0, offsetX.value))
);

const isOpen = computed(() => openRowId.value === props.rowId);

watch(
  () => openRowId.value,
  newId => {
    if (newId !== props.rowId && offsetX.value !== 0) {
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

  const base = isOpen.value ? -actionsWidth.value : 0;
  offsetX.value = base + deltaX;

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

  if (offsetX.value < -props.threshold) {
    offsetX.value = -actionsWidth.value;
    openRowId.value = props.rowId;
  } else {
    offsetX.value = 0;
    if (openRowId.value === props.rowId) {
      openRowId.value = null;
    }
  }
};

const onTransitionEnd = () => {
  isAnimating.value = false;
};

const onActionClick = actionKey => {
  emit('action', actionKey);
  isAnimating.value = true;
  offsetX.value = 0;
  openRowId.value = null;
};
</script>

<template>
  <div class="relative overflow-hidden rounded-lg">
    <!-- Action buttons behind -->
    <div
      class="absolute inset-y-0 right-0 flex items-stretch"
      :style="{ width: `${actionsWidth}px` }"
    >
      <button
        v-for="action in actions"
        :key="action.key"
        class="flex flex-col items-center justify-center w-[72px] text-white text-xs font-medium gap-1"
        :class="action.color"
        @click.stop="onActionClick(action.key)"
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
