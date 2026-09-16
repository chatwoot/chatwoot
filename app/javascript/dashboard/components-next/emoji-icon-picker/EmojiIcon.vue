<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { isIconValue, iconClassFor } from './constants';

// Renders a saved picker value: a color-tinted icon or an emoji.
const props = defineProps({
  value: {
    type: String,
    default: '',
  },
  color: {
    type: String,
    default: '',
  },
});

const isIcon = computed(() => isIconValue(props.value));
const iconClass = computed(() => iconClassFor(props.value));
const iconStyle = computed(() =>
  props.color ? { color: props.color } : undefined
);
</script>

<template>
  <span class="inline-flex items-center justify-center leading-none">
    <Icon
      v-if="isIcon"
      :icon="iconClass"
      class="size-full"
      :style="iconStyle"
    />
    <span v-else v-dompurify-html="value" />
  </span>
</template>
