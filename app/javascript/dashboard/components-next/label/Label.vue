<script setup>
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: [Object, String],
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  color: {
    type: String,
    default: 'slate',
    validator: value =>
      ['slate', 'amber', 'teal', 'ruby', 'blue', 'iris'].includes(value),
  },
});

const COLOR_CLASSES = {
  slate: 'bg-s-brand-soft outline-s-border text-s-primary',
  amber: 'bg-s-warning-soft outline-s-warning/30 text-s-warning-text',
  teal: 'bg-s-success-soft outline-s-success/30 text-s-success-text',
  ruby: 'bg-s-error-soft outline-s-error/30 text-s-error-text',
  blue: 'bg-s-brand-soft outline-s-brand/30 text-s-brand-text',
  iris: 'bg-s-subtle outline-s-brand/30 text-s-brand-text',
};

const isStringLabel = computed(() => typeof props.label === 'string');

const labelTitle = computed(() => {
  return isStringLabel.value ? props.label : props.label?.title;
});

const labelDescription = computed(() => {
  return (!isStringLabel.value && props.label?.description) || '';
});

const labelColor = computed(() => {
  return isStringLabel.value ? null : props.label.color;
});

const colorClasses = computed(() => COLOR_CLASSES[props.color]);
</script>

<template>
  <div
    :title="labelDescription"
    class="rounded-lg -outline-offset-1 outline outline-1 inline-flex items-center flex-shrink-0"
    :class="[
      colorClasses,
      compact ? 'px-1.5 h-6 gap-1 rounded-md' : 'px-2.5 h-8 gap-1.5 rounded-lg',
    ]"
  >
    <span
      v-if="labelColor"
      class="rounded-sm flex-shrink-0"
      :class="compact ? 'size-1.5' : 'size-2'"
      :style="{ background: labelColor }"
    />
    <slot v-else name="icon" />
    <span
      class="whitespace-nowrap"
      :class="compact ? 'text-label-small' : 'text-label !font-420'"
    >
      {{ labelTitle }}
    </span>
    <slot name="action" />
  </div>
</template>
