<script setup>
import { ref, computed, inject, nextTick, useSlots, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useThrottleFn } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationLabels: {
    type: Array,
    required: true,
  },
  disableToggle: {
    type: Boolean,
    default: false,
  },
});

const slots = useSlots();
const { t } = useI18n();

const accountLabels = useMapGetter('labels/getLabels');

const activeLabels = computed(() => {
  return accountLabels.value.filter(({ title }) =>
    props.conversationLabels.includes(title)
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

const hiddenLabelsTooltip = computed(() => {
  if (!props.disableToggle || !showExpandLabelButton.value) return '';
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
    v-resize="throttledCalculate"
    data-labels-container
    class="flex items-center flex-shrink min-w-0 min-h-6 gap-x-1.5 gap-y-1 [&:not(:has([data-label],[data-before-slot]))]:hidden"
    :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
  >
    <slot name="before" />

    <div
      v-for="(label, index) in activeLabels"
      :key="label ? label.id : index"
      data-label
      :title="label.description"
      class="bg-n-button-color px-1.5 h-6 gap-1 rounded-md -outline-offset-1 outline outline-1 outline-n-container inline-flex items-center flex-shrink-0"
      :class="{
        'invisible absolute': !showAllLabels && index > labelPosition,
      }"
    >
      <span
        class="rounded-sm size-1.5 flex-shrink-0"
        :style="{ background: label.color }"
      />
      <span class="font-440 text-xs text-n-slate-12 whitespace-nowrap">
        {{ label.title }}
      </span>
    </div>
    <Button
      v-if="showExpandLabelButton"
      v-tooltip.top="{
        content: tooltipText,
        delay: { show: 1000, hide: 0 },
      }"
      :label="
        !showAllLabels && hiddenLabelsCount > 0 ? `+${hiddenLabelsCount}` : ''
      "
      xs
      slate
      :no-animation="disableToggle"
      :icon="
        !showAllLabels && hiddenLabelsCount > 0 ? '' : 'i-lucide-chevron-left'
      "
      class="!py-0 !px-1.5 flex-shrink-0 !rounded-md !bg-n-button-color -outline-offset-1"
      :class="{ 'cursor-default': disableToggle }"
      @click="onShowLabels"
    />
  </div>
  <template v-else />
</template>
