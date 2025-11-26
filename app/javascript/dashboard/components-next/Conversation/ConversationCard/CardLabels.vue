<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
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

const computeVisibleLabelPosition = () => {
  if (!labelContainer.value) return;

  const containerElement = labelContainer.value.querySelector(
    '[data-labels-container]'
  );
  if (!containerElement) return;

  const labels = containerElement.querySelectorAll('[data-label]');
  if (labels.length === 0) return;

  // Calculate before slot width dynamically
  const beforeSlotElement =
    containerElement.querySelector('[data-before-slot]');
  const beforeSlotWidth = beforeSlotElement
    ? beforeSlotElement.offsetWidth + 6
    : 0; // +6 for gap

  let labelOffset = 0;
  showExpandLabelButton.value = false;
  const buttonWidth = 40; // Approximate width for +N button
  const gapWidth = 6; // gap-1.5 = 6px
  const availableWidth =
    containerElement.clientWidth - buttonWidth - beforeSlotWidth;

  labels.forEach((label, index) => {
    labelOffset += label.offsetWidth + gapWidth;

    if (labelOffset < availableWidth) {
      labelPosition.value = index;
    } else {
      showExpandLabelButton.value = labels.length > 1;
    }
  });
};

watch(
  activeLabels,
  () => {
    nextTick(computeVisibleLabelPosition);
  },
  { immediate: true }
);

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
  <div ref="labelContainer" v-resize="computeVisibleLabelPosition">
    <div
      v-if="activeLabels.length || $slots.before"
      data-labels-container
      class="flex items-center flex-shrink min-w-0 gap-x-1.5 gap-y-1"
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
        <span class="font-440 text-xs text-n-slate-12 whitespace-nowrap">{{
          label.title
        }}</span>
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
  </div>
</template>
