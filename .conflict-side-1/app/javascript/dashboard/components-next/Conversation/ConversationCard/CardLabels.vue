<script setup>
import { ref, computed } from 'vue';

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
    SHORT: 8, // For labels <= 5 chars
    LONG: 6, // For labels > 5 chars
  },
  BASE_WIDTH: 12, // dot + gap
  THRESHOLD: 5, // character length threshold
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
    class="flex items-center gap-2.5 w-full min-w-0 h-6 overflow-hidden"
  >
    <template v-for="(label, index) in visibleLabels" :key="label.id">
      <div
        class="flex items-center gap-1.5 min-w-0"
        :class="[
          index !== visibleLabels.length - 1
            ? 'flex-shrink-0 text-ellipsis'
            : 'flex-shrink',
        ]"
      >
        <div
          :style="{ backgroundColor: label.color }"
          class="size-1.5 rounded-full flex-shrink-0"
        />
        <span
          class="text-sm text-n-slate-10 whitespace-nowrap"
          :class="{ truncate: index === visibleLabels.length - 1 }"
        >
          {{ label.title }}
        </span>
      </div>
    </template>
  </div>
</template>
