<script setup>
import { ref, computed, watch, onMounted, nextTick, useSlots } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationLabels: {
    type: Array,
    required: true,
  },
});

const slots = useSlots();
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
  const beforeSlot = slots.before ? 100 : 0;
  if (!labelContainer.value) return;

  const labels = labelContainer.value.querySelectorAll('[data-label]');
  if (labels.length === 0) return;

  let labelOffset = 0;
  showExpandLabelButton.value = false;
  const buttonWidth = 40; // Approximate width for +N button
  const gapWidth = 6; // gap-1.5 = 6px
  const availableWidth =
    labelContainer.value.clientWidth - buttonWidth - beforeSlot;

  labels.forEach((label, index) => {
    labelOffset += label.offsetWidth + gapWidth;

    if (labelOffset < availableWidth) {
      labelPosition.value = index;
    } else {
      showExpandLabelButton.value = labels.length > 1;
    }
  });
};

watch(activeLabels, () => {
  nextTick(() => computeVisibleLabelPosition());
});

onMounted(() => {
  nextTick(() => computeVisibleLabelPosition());
});

const hiddenLabelsCount = computed(() => {
  if (!showExpandLabelButton.value || showAllLabels.value) return 0;
  return activeLabels.value.length - labelPosition.value - 1;
});

const onShowLabels = e => {
  e.stopPropagation();
  showAllLabels.value = !showAllLabels.value;
  nextTick(() => computeVisibleLabelPosition());
};
</script>

<template>
  <div ref="labelContainer" v-resize="computeVisibleLabelPosition">
    <div
      v-if="activeLabels.length || $slots.before"
      class="flex items-end flex-shrink min-w-0 gap-x-1.5 gap-y-1"
      :class="{ 'h-auto overflow-visible flex-row flex-wrap': showAllLabels }"
    >
      <div
        v-for="(label, index) in activeLabels"
        :key="label ? label.id : index"
        data-label
        :title="label.description"
        class="bg-n-button-color px-1.5 h-6 gap-1 rounded-md outline outline-1 outline-n-container inline-flex items-center flex-shrink-0"
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
        :title="
          showAllLabels
            ? $t('CONVERSATION.CARD.HIDE_LABELS')
            : $t('CONVERSATION.CARD.SHOW_LABELS')
        "
        :label="
          !showAllLabels && hiddenLabelsCount > 0 ? `+${hiddenLabelsCount}` : ''
        "
        xs
        slate
        :icon="
          !showAllLabels && hiddenLabelsCount > 0 ? '' : 'i-lucide-chevron-left'
        "
        class="!py-0 !px-1.5 flex-shrink-0 !rounded-md !bg-n-button-color"
        @click="onShowLabels"
      />
    </div>
  </div>
</template>
