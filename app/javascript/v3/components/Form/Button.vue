<template>
  <button
    class="inline-flex items-center gap-1 text-sm font-medium reset-base rounded-xl w-fit"
    :type="type"
    :class="buttonClasses"
    :disabled="isDisabled"
    @click="handleClick"
  >
    <fluent-icon
      v-if="icon && !iconOnly"
      :size="iconSize"
      :icon="icon"
      class="flex-shrink-0"
    />
    <span
      v-if="$slots.default && !iconOnly"
      class="text-sm font-medium truncate"
      :class="{ 'text-left rtl:text-right': size !== 'expanded' }"
    >
      <slot />
    </span>
    <fluent-icon
      v-if="rightIcon || iconOnly"
      :size="iconSize"
      icon="chevron-right"
      class="flex-shrink-0"
    />
  </button>
</template>
<script setup>
import { computed, defineProps } from 'vue';

const props = defineProps({
  type: {
    type: String,
    default: 'submit',
  },
  variant: {
    type: String,
    default: '',
  },
  size: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
  colorScheme: {
    type: String,
    default: 'primary',
  },
  classNames: {
    type: [String, Object],
    default: '',
  },
  isDisabled: {
    type: Boolean,
    default: false,
  },
  rightIcon: {
    type: Boolean,
    default: false,
  },
  iconOnly: {
    type: Boolean,
    default: false,
  },
});
const emits = defineEmits(['click']);

const colorClass = computed(() => {
  if (props.isDisabled) {
    return 'bg-ash-200 text-ash-600 cursor-not-allowed';
  }
  if (props.colorScheme === 'primary') {
    if (props.variant === 'outline') {
      return 'text-primary-800 border  border-primary-400 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400';
    }
    if (props.variant === 'ghost') {
      return 'text-primary-800 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400';
    }
    return 'bg-primary-600 border-primary-600 text-white hover:bg-primary-700 active:bg-primary-700 focus:ring focus:ring-offset-1 focus:ring-primary-400';
  }
  if (props.colorScheme === 'secondary') {
    return 'bg-ash-100 text-ash-900 hover:bg-ash-200 active:bg-ash-200 focus:ring focus:ring-offset-1 focus:ring-ash-400';
  }
  if (props.colorScheme === 'danger') {
    return 'bg-ruby-600 text-white hover:bg-ruby-700 active:bg-ruby-700 focus:ring focus:ring-offset-1 focus:ring-ruby-400';
  }
  return 'bg-primary-500 text-white';
});

const sizeClass = computed(() => {
  if (props.size === 'medium') {
    return 'px-3 py-2 text-sm';
  }
  return 'px-4 py-2.5 text';
});

const iconSize = computed(() => {
  switch (props.size) {
    case 'medium':
      return 16;
    case 'large':
      return 18;

    default:
      return 16;
  }
});

const handleClick = () => {
  emits('click');
};

const buttonClasses = computed(() => [
  colorClass.value,
  sizeClass.value,
  props.classNames,
]);
</script>
