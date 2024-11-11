<script setup>
import { computed, useSlots } from 'vue';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  label: {
    type: [String, Number],
    default: '',
  },
  variant: {
    type: String,
    default: 'solid',
    validator: value =>
      ['solid', 'outline', 'faded', 'link', 'ghost'].includes(value),
  },
  color: {
    type: String,
    default: 'blue',
    validator: value =>
      ['blue', 'ruby', 'amber', 'slate', 'teal'].includes(value),
  },
  size: {
    type: String,
    default: 'md',
    validator: value => ['xs', 'sm', 'md', 'lg'].includes(value),
  },
  icon: {
    type: String,
    default: '',
  },
  trailingIcon: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const slots = useSlots();

const STYLE_CONFIG = {
  colors: {
    blue: {
      solid: 'bg-n-brand text-white hover:brightness-110 outline-transparent',
      faded:
        'bg-n-brand/10 text-n-blue-text hover:bg-n-brand/20 outline-transparent',
      outline: 'text-n-blue-text outline-n-blue-border',
      link: 'text-n-blue-text hover:underline outline-transparent',
    },
    ruby: {
      solid: 'bg-n-ruby-9 text-white hover:bg-n-ruby-10 outline-transparent',
      faded:
        'bg-n-ruby-9/10 text-n-ruby-11 hover:bg-n-ruby-9/20 outline-transparent',
      outline: 'text-n-ruby-11 hover:bg-n-ruby-9/10 outline-n-ruby-8',
      link: 'text-n-ruby-9 hover:underline outline-transparent',
    },
    amber: {
      solid: 'bg-n-amber-9 text-white hover:bg-n-amber-10 outline-transparent',
      faded:
        'bg-n-amber-9/10 text-n-slate-12 hover:bg-n-amber-9/20 outline-transparent',
      outline: 'text-n-amber-11 hover:bg-n-amber-9/10 outline-n-amber-9',
      link: 'text-n-amber-9 hover:underline outline-transparent',
    },
    slate: {
      solid:
        'bg-n-solid-3 dark:hover:bg-n-solid-2 hover:bg-n-alpha-2 text-n-slate-12 outline-n-container',
      faded:
        'bg-n-slate-9/10 text-n-slate-12 hover:bg-n-slate-9/20 outline-transparent',
      outline: 'text-n-slate-11 outline-n-strong hover:bg-n-slate-9/10',
      link: 'text-n-slate-11 hover:text-n-slate-12 hover:underline outline-transparent',
    },
    teal: {
      solid: 'bg-n-teal-9 text-white hover:bg-n-teal-10 outline-transparent',
      faded:
        'bg-n-teal-9/10 text-n-slate-12 hover:bg-n-teal-9/20 outline-transparent',
      outline: 'text-n-teal-11 hover:bg-n-teal-9/10 outline-n-teal-9',
      link: 'text-n-teal-9 hover:underline outline-transparent',
    },
  },
  sizes: {
    regular: {
      xs: 'h-6 px-2',
      sm: 'h-8 px-3',
      md: 'h-10 px-4',
      lg: 'h-12 px-5',
    },
    iconOnly: {
      xs: 'h-6 w-6 p-0',
      sm: 'h-8 w-8 p-0',
      md: 'h-10 w-10 p-0',
      lg: 'h-12 w-12 p-0',
    },
    link: {
      xs: 'p-0',
      sm: 'p-0',
      md: 'p-0',
      lg: 'p-0',
    },
  },
  fontSize: {
    xs: 'text-xs',
    sm: 'text-sm',
    md: 'text-sm font-medium',
    lg: 'text-base',
  },
  base: 'inline-flex items-center justify-center min-w-0 gap-2 transition-all duration-200 ease-in-out border-0 rounded-lg outline-1 outline disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50',
};

const variantClasses = computed(() => {
  const variantMap = {
    ghost: 'text-n-slate-12 hover:bg-n-alpha-2 outline-transparent',
    link: `${STYLE_CONFIG.colors[props.color].link} p-0 font-medium underline-offset-4`,
    outline: STYLE_CONFIG.colors[props.color].outline,
    faded: STYLE_CONFIG.colors[props.color].faded,
    solid: STYLE_CONFIG.colors[props.color].solid,
  };

  return variantMap[props.variant];
});

const isIconOnly = computed(() => !props.label && !slots.default);
const isLink = computed(() => props.variant === 'link');

const buttonClasses = computed(() => {
  const sizeConfig = isIconOnly.value ? 'iconOnly' : 'regular';
  const classes = [
    variantClasses.value,
    props.variant !== 'link' && STYLE_CONFIG.sizes[sizeConfig][props.size],
  ].filter(Boolean);

  return classes.join(' ');
});

const linkButtonClasses = computed(() => {
  const classes = [
    variantClasses.value,
    STYLE_CONFIG.sizes.link[props.size],
  ].filter(Boolean);

  return classes.join(' ');
});
</script>

<template>
  <button
    :class="{
      [STYLE_CONFIG.base]: true,
      [isLink ? linkButtonClasses : buttonClasses]: true,
      [STYLE_CONFIG.fontSize[size]]: true,
      'flex-row-reverse': trailingIcon && !isIconOnly,
    }"
  >
    <slot v-if="(icon || $slots.icon) && !isLoading" name="icon">
      <Icon :icon="icon" class="flex-shrink-0" />
    </slot>

    <Spinner v-if="isLoading" class="!w-5 !h-5 flex-shrink-0" />

    <slot v-if="label || $slots.default" name="default">
      <span v-if="label" class="min-w-0 truncate">{{ label }}</span>
    </slot>
  </button>
</template>
