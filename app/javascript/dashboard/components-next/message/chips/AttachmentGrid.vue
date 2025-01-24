<script setup>
import { computed } from 'vue';
import ImageChip from './Image.vue';
import VideoChip from './Video.vue';

import { ATTACHMENT_TYPES } from '../constants';

const props = defineProps({
  attachments: {
    type: Array,
    required: true,
    validator: value => Array.isArray(value) && value.length > 0,
  },
});

const MAX_DISPLAYED = 5;

const visibleAttachments = computed(() =>
  props.attachments.slice(0, MAX_DISPLAYED)
);

const remainingCount = computed(() =>
  Math.max(0, props.attachments.length - MAX_DISPLAYED)
);

const gridClass = computed(() => {
  const count = props.attachments.length;
  const base = 'grid gap-2 w-full';

  if (count === 1) return `${base} grid-cols-1`;

  const classes = {
    2: `${base} grid-cols-2 max-h-[400px]`,
    3: `${base} grid-cols-2 max-h-[400px]`,
    4: `${base} grid-cols-2 max-h-[400px]`,
    5: `${base} grid-cols-3 max-h-[400px]`,
  };

  return classes[count] || classes[5];
});

const itemClass = computed(() => index => {
  const count = props.attachments.length;
  const base = 'relative overflow-hidden rounded-lg';

  if (count === 1) return `${base} w-fit h-[400px]`; //  w-full h-auto, TODO: check this

  if (count === 3 && index === 0) return `${base} row-span-2 h-[392px]`;
  if (count >= 5 && index === 0) return `${base} col-span-2 h-[192px]`;

  return count === 2 ? `${base} h-[400px]` : `${base} h-[192px]`;
});

const shouldShowOverlay = computed(
  () => index => remainingCount.value > 0 && index === MAX_DISPLAYED - 1
);

const componentMap = {
  [ATTACHMENT_TYPES.IMAGE]: ImageChip,
  [ATTACHMENT_TYPES.VIDEO]: VideoChip,
};

const getComponent = fileType =>
  componentMap[fileType?.toLowerCase()] || componentMap[ATTACHMENT_TYPES.IMAGE];
</script>

<template>
  <div :class="gridClass">
    <div
      v-for="(attachment, index) in visibleAttachments"
      :key="attachment.id"
      :class="itemClass(index)"
    >
      <component
        :is="getComponent(attachment.fileType)"
        :attachment="attachment"
        :remaining-count="remainingCount"
        :should-show-overlay="shouldShowOverlay(index)"
      />
    </div>
  </div>
</template>
