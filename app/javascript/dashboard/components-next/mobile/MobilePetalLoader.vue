<script setup>
import { computed } from 'vue';

const props = defineProps({
  progress: {
    type: Number,
    default: 0,
  },
  spinning: {
    type: Boolean,
    default: false,
  },
});

const SPOKE_ANGLES = [0, 45, 90, 135, 180, 225, 270, 315];
const MIN_OPACITY = 0.08;
const MAX_OPACITY = 1;

const normalizedProgress = computed(() => {
  if (props.spinning) return 1;
  return Math.min(Math.max(props.progress, 0), 1);
});

const spokeStates = computed(() => {
  const filledSpokes = normalizedProgress.value * SPOKE_ANGLES.length;

  return SPOKE_ANGLES.map((angle, index) => {
    const fillAmount = props.spinning
      ? 1
      : Math.min(Math.max(filledSpokes - index, 0), 1);

    return {
      angle,
      opacity: MIN_OPACITY + fillAmount * (MAX_OPACITY - MIN_OPACITY),
      y1: -22 - fillAmount * 12,
      y2: -12 - fillAmount * 4,
      strokeWidth: 6 + fillAmount * 2,
    };
  });
});
</script>

<template>
  <svg
    viewBox="0 0 100 100"
    class="size-7"
    :class="{ 'animate-spin': spinning }"
    fill="none"
    aria-hidden="true"
  >
    <g transform="translate(50 50)">
      <line
        v-for="spoke in spokeStates"
        :key="spoke.angle"
        x1="0"
        x2="0"
        :y1="spoke.y1"
        :y2="spoke.y2"
        :transform="`rotate(${spoke.angle})`"
        stroke="#5F6368"
        stroke-linecap="round"
        :stroke-width="spoke.strokeWidth"
        :stroke-opacity="spoke.opacity"
      />
    </g>
  </svg>
</template>
