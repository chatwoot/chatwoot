<template>
  <button
    class="inline-flex items-center gap-1 text-sm font-medium reset-base rounded-xl w-fit"
    :class="buttonClasses"
    v-bind="$attrs"
  >
    <fluent-icon
      v-if="icon && !trailingIcon"
      size="1.16em"
      :icon="icon"
      class="flex-shrink-0"
    />
    <span
      v-if="$slots.default"
      class="text-sm font-medium truncate ltr:text-left rtl:text-right"
    >
      <slot />
    </span>
    <fluent-icon
      v-if="icon && trailingIcon"
      size="1.16em"
      :icon="icon"
      class="flex-shrink-0"
    />
  </button>
</template>
<script setup>
import { computed, defineProps, useAttrs } from 'vue';

const props = defineProps({
  variant: {
    type: String,
    default: 'solid',
    validator: value => ['outline', 'ghost', 'solid'].includes(value),
  },
  size: {
    type: String,
    default: 'large',
    validator: value => ['medium', 'large'].includes(value),
  },
  icon: {
    type: String,
    default: '',
  },
  colorScheme: {
    type: String,
    default: 'primary',
    validator: value => ['primary', 'secondary', 'danger'].includes(value),
  },
  trailingIcon: {
    type: Boolean,
    default: false,
  },
});

const attrs = useAttrs();

const baseClasses = {
  outline: 'outline outline-1 -outline-offset-1 focus:ring focus:ring-offset-1',
  ghost: 'hover:text-600 active:text-600 focus:ring focus:ring-offset-1',
  solid: 'hover:bg-700 active:bg-700 focus:ring focus:ring-offset-1',
};

const colorClass = computed(() => {
  if (attrs.disabled) {
    return 'bg-ash-200 text-ash-600 cursor-not-allowed';
  }

  const styleMap = {
    primary: {
      outline: `${baseClasses.outline} outline-primary-400 hover:text-primary-600 active:text-primary-600 focus:ring-primary-400`,
      ghost: `${baseClasses.ghost} focus:ring-primary-400`,
      solid: `${baseClasses.solid} bg-primary-600 text-white focus:ring-primary-400`,
    },
    secondary: {
      outline: `${baseClasses.outline} outline-ash-400 hover:text-ash-600 active:text-ash-600 focus:ring-ash-400`,
      ghost: `${baseClasses.ghost} focus:ring-ash-400`,
      solid: `${baseClasses.solid} bg-ash-100 text-ash-900 focus:ring-ash-400`,
    },
    danger: {
      outline: `${baseClasses.outline} outline-ruby-400 hover:text-ruby-600 active:text-ruby-600 focus:ring-ruby-400`,
      ghost: `${baseClasses.ghost} focus:ring-ruby-400`,
      solid: `${baseClasses.solid} bg-ruby-600 text-white focus:ring-ruby-400`,
    },
  };

  const schemeStyles = styleMap[props.colorScheme];
  return schemeStyles[props.variant] || schemeStyles.solid;
});

const sizeClass = computed(() => {
  if (props.size === 'medium') {
    return 'h-8 px-3 py-1.5 text-sm';
  }
  return 'h-10 px-4 py-2.5 text';
});

const buttonClasses = computed(() => [colorClass.value, sizeClass.value]);
</script>
