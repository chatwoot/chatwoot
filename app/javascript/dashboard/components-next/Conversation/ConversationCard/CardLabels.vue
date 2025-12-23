<script setup>
import {
  ref,
  computed,
  inject,
  nextTick,
  useSlots,
  watch,
  useAttrs,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useThrottleFn } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  labels: {
    type: Array,
    required: true,
  },
  disableToggle: {
    type: Boolean,
    default: false,
  },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();
const slots = useSlots();
const { t } = useI18n();

const accountLabels = useMapGetter('labels/getLabels');

const activeLabels = computed(() => {
  return accountLabels.value.filter(({ title }) =>
    props.labels.includes(title)
  );
});

const showAllLabels = ref(false);
const showExpandLabelButton = ref(false);
const labelPosition = ref(-1);
const labelContainer = ref(null);

// Show if there are labels OR if before slot exists
const showSection = computed(
  () => activeLabels.value.length > 0 || !!slots.before
);

const computeVisibleLabelPosition = () => {
  const container = labelContainer.value;
  if (!container || activeLabels.value.length === 0) {
    showExpandLabelButton.value = false;
    return;
  }

  const labels = container.querySelectorAll('[data-label]');
  if (labels.length === 0) {
    showExpandLabelButton.value = false;
    return;
  }

  // Early exit if all labels are visible
  if (showAllLabels.value) return;

  const beforeSlot = container.querySelector('[data-before-slot]');
  const beforeSlotWidth = beforeSlot?.offsetWidth ?? 0;
  const availableWidth = container.clientWidth - 46 - beforeSlotWidth;

  let totalWidth = 0;
  const labelsArray = Array.from(labels);

  // Find last visible label index using some() - stops early on overflow
  const overflowIndex = labelsArray.findIndex(label => {
    totalWidth += label.offsetWidth + 6;
    return totalWidth > availableWidth;
  });

  const visibleIndex =
    overflowIndex === -1 ? labelsArray.length - 1 : overflowIndex - 1;

  labelPosition.value = visibleIndex;
  showExpandLabelButton.value = visibleIndex < labelsArray.length - 1;
};

const throttledCalculate = useThrottleFn(computeVisibleLabelPosition, 16);

watch(activeLabels, () => nextTick(throttledCalculate), { immediate: true });

// Recalculate when parent triggers (e.g., tab changes in ChatList)
// Needed because inbox conversation view shows metadata inside CardLabels, affecting available width
const recalculateKey = inject('recalculateLabelsKey', null);

if (recalculateKey) {
  watch(recalculateKey, () => nextTick(throttledCalculate));
}

const hiddenLabelsCount = computed(() => {
  if (!showExpandLabelButton.value || showAllLabels.value) return 0;
  return activeLabels.value.length - labelPosition.value - 1;
});

// Check if all labels are hidden (none visible)
const allLabelsHidden = computed(() => {
  return labelPosition.value === -1 && activeLabels.value.length > 0;
});

// Label text for button when disableToggle is true and all labels are hidden
const labelsCountText = computed(() => {
  if (props.disableToggle && allLabelsHidden.value) {
    return t('CONVERSATION.CARD.LABELS_COUNT', {
      count: activeLabels.value.length,
    });
  }
  if (!showAllLabels.value && hiddenLabelsCount.value > 0) {
    return `+${hiddenLabelsCount.value}`;
  }
  return '';
});

const hiddenLabelsTooltip = computed(() => {
  if (!props.disableToggle) return '';
  // When all labels are hidden, show all label titles
  if (allLabelsHidden.value) {
    return activeLabels.value.map(label => label.title).join(', ');
  }
  if (!showExpandLabelButton.value) return '';
  const hiddenLabels = activeLabels.value.slice(labelPosition.value + 1);
  return hiddenLabels.map(label => label.title).join(', ');
});

const tooltipText = computed(() => {
  if (props.disableToggle && hiddenLabelsTooltip.value) {
    return hiddenLabelsTooltip.value;
  }
  return showAllLabels.value
    ? t('CONVERSATION.CARD.HIDE_LABELS')
    : t('CONVERSATION.CARD.SHOW_LABELS');
});

const onShowLabels = e => {
  e.stopPropagation();
  if (props.disableToggle) return;
  showAllLabels.value = !showAllLabels.value;
  nextTick(() => computeVisibleLabelPosition());
};
</script>

<template>
  <div
    v-if="showSection"
    ref="labelContainer"
    v-bind="attrs"
    v-resize="throttledCalculate"
    data-labels-container
    class="flex items-center flex-shrink min-w-0 min-h-6 gap-x-1.5 gap-y-1 [&:not(:has([data-label],[data-before-slot]))]:hidden"
    :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
  >
    <slot name="before" />

    <Label
      v-for="(label, index) in activeLabels"
      :key="label ? label.id : index"
      data-label
      :label="label"
      compact
      :class="{
        'invisible absolute': !showAllLabels && index > labelPosition,
      }"
    />
    <Button
      v-if="showExpandLabelButton || (disableToggle && allLabelsHidden)"
      v-tooltip.top="{
        content: tooltipText,
        delay: { show: 1000, hide: 0 },
      }"
      :label="labelsCountText"
      xs
      slate
      :no-animation="disableToggle"
      :icon="labelsCountText ? '' : 'i-lucide-chevron-left'"
      class="!py-0 !px-1.5 flex-shrink-0 !rounded-md !bg-n-button-color -outline-offset-1"
      :class="{ 'cursor-default': disableToggle }"
      @click="onShowLabels"
    />
  </div>
  <template v-else />
</template>
