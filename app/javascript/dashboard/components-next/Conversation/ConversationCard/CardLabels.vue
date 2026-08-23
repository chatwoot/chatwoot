<script setup>
import { ref, computed } from 'vue';
import { tintStylesFromHex } from 'dashboard/helper/colorHelper';

const props = defineProps({
  conversationLabels: {
    type: Array,
    required: true,
  },
  accountLabels: {
    type: Array,
    required: true,
  },
});

const WIDTH_CONFIG = Object.freeze({
  DEFAULT_WIDTH: 80,
  CHAR_WIDTH: {
    SHORT: 8,
    LONG: 6,
  },
  BASE_WIDTH: 16,
  THRESHOLD: 5,
});

const containerRef = ref(null);
const maxLabels = ref(1);

const activeLabels = computed(() => {
  const labelSet = new Set(props.conversationLabels);
  return props.accountLabels?.filter(({ title }) => labelSet.has(title));
});

const calculateLabelWidth = ({ title = '' }) => {
  const charWidth =
    title.length > WIDTH_CONFIG.THRESHOLD
      ? WIDTH_CONFIG.CHAR_WIDTH.LONG
      : WIDTH_CONFIG.CHAR_WIDTH.SHORT;

  return title.length * charWidth + WIDTH_CONFIG.BASE_WIDTH;
};

const getAverageWidth = labels => {
  if (!labels.length) return WIDTH_CONFIG.DEFAULT_WIDTH;

  const totalWidth = labels.reduce(
    (sum, label) => sum + calculateLabelWidth(label),
    0
  );

  return totalWidth / labels.length;
};

const visibleLabels = computed(() =>
  activeLabels.value?.slice(0, maxLabels.value)
);

const updateVisibleLabels = () => {
  if (!containerRef.value) return;

  const containerWidth = containerRef.value.offsetWidth;
  const avgWidth = getAverageWidth(activeLabels.value);

  maxLabels.value = Math.max(1, Math.floor(containerWidth / avgWidth));
};
</script>

<template>
  <div
    ref="containerRef"
    v-resize="updateVisibleLabels"
    class="flex items-center gap-1.5 w-full min-w-0 h-6 overflow-hidden"
  >
    <span
      v-for="(label, index) in visibleLabels"
      :key="label.id"
      class="inline-flex items-center rounded-md border px-1.5 py-0.5 text-xxs font-medium min-w-0"
      :class="[
        index !== visibleLabels.length - 1 ? 'flex-shrink-0' : 'flex-shrink',
      ]"
      :style="tintStylesFromHex(label.color)"
    >
      <span
        class="whitespace-nowrap"
        :class="{ truncate: index === visibleLabels.length - 1 }"
      >
        {{ label.title }}
      </span>
    </span>
  </div>
</template>
