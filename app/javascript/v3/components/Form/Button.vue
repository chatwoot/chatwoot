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
      class="text-sm font-medium text-left truncate rtl:text-right"
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

  const styleMap = {
    primary: {
      outline:
        'text-primary-800 border  border-primary-400 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400',
      ghost:
        'text-primary-800 hover:text-primary-600 active:text-primary-600 focus:ring focus:ring-offset-1 focus:ring-primary-400',
      default:
        'bg-primary-600 border border-primary-600 text-white hover:bg-primary-700 active:bg-primary-700 focus:ring focus:ring-offset-1 focus:ring-primary-400',
    },
    secondary: {
      outline:
        'text-ash-800 border border-ash-400 hover:text-ash-600 active:text-ash-600 focus:ring focus:ring-offset-1 focus:ring-ash-400',
      ghost:
        'text-ash-800 hover:text-ash-600 active:text-ash-600 focus:ring focus:ring-offset-1 focus:ring-ash-400',
      default:
        'bg-ash-100 text-ash-900 hover:bg-ash-200 active:bg-ash-200 focus:ring focus:ring-offset-1 focus:ring-ash-400',
    },
    danger: {
      outline:
        'text-ruby-800 border border-ruby-400 hover:text-ruby-600 active:text-ruby-600 focus:ring focus:ring-offset-1 focus:ring-ruby-400',
      ghost:
        'text-ruby-800 hover:text-ruby-600 active:text-ruby-600 focus:ring focus:ring-offset-1 focus:ring-ruby-400',
      default:
        'bg-ruby-600 text-white hover:bg-ruby-700 active:bg-ruby-700 focus:ring focus:ring-offset-1 focus:ring-ruby-400',
    },
  };

  const schemeStyles = styleMap[props.colorScheme] || {};
  const variantStyle = schemeStyles[props.variant] || schemeStyles.default;

  return variantStyle;
});

const sizeClass = computed(() => {
  if (props.size === 'medium') {
    return 'px-3 py-2 text-sm';
  }
  return 'px-4 py-2.5 text';
});

const iconSize = computed(() => {
  if (props.size === 'medium') {
    return 14;
  }
  return 16;
});
const buttonClasses = computed(() => [
  colorClass.value,
  sizeClass.value,
  props.classNames,
]);
const handleClick = () => {
  emits('click');
};
</script>
