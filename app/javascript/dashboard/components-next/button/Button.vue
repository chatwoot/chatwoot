<script setup>
import { computed } from 'vue';

import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  variant: {
    type: String,
    default: 'default',
    validator: value =>
      [
        'default',
        'destructive',
        'outline',
        'secondary',
        'ghost',
        'link',
      ].includes(value),
  },
  textVariant: {
    type: String,
    default: '',
    validator: value =>
      ['', 'default', 'success', 'warning', 'danger', 'info'].includes(value),
  },
  size: {
    type: String,
    default: 'default',
    validator: value => ['default', 'sm', 'lg'].includes(value),
  },
  type: {
    type: String,
    default: 'button',
    validator: value => ['button', 'submit', 'reset'].includes(value),
  },
  icon: {
    type: String,
    default: '',
  },
  emoji: {
    type: String,
    default: '',
  },
  iconPosition: {
    type: String,
    default: 'left',
    validator: value => ['left', 'right'].includes(value),
  },
  iconLib: {
    type: String,
    default: 'fluent',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click']);

const buttonVariants = {
  variant: {
    default:
      'bg-n-brand text-white dark:text-white hover:bg-woot-600 dark:hover:bg-woot-600',
    destructive: 'bg-n-ruby-9 text-white dark:text-white hover:bg-n-ruby-10',
    outline:
      'border border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6',
    secondary: 'bg-n-solid-3 text-n-slate-12 hover:bg-n-solid-2',
    ghost: 'text-n-slate-12',
    link: 'text-n-brand underline-offset-4 hover:underline dark:hover:underline',
  },
  size: {
    default: 'h-10 px-4 py-2',
    sm: 'h-8 px-3 py-1',
    lg: 'h-12 px-5 py-3',
  },
  text: {
    default:
      '!text-n-brand dark:!text-n-brand hover:!text-woot-600 dark:hover:!text-woot-600',
    success:
      '!text-green-500 dark:!text-green-500 hover:!text-green-600 dark:hover:!text-green-600',
    warning:
      '!text-amber-600 dark:!text-amber-600 hover:!text-amber-600 dark:hover:!text-amber-600',
    danger: '!text-n-ruby-11 hover:!text-n-ruby-10',
    info: '!text-n-slate-12 hover:!text-n-slate-11',
  },
};

const buttonClasses = computed(() => {
  const classes = [
    buttonVariants.variant[props.variant],
    buttonVariants.size[props.size],
  ];

  if (props.textVariant && buttonVariants.text[props.textVariant]) {
    classes.push(buttonVariants.text[props.textVariant]);
  }

  return classes.join(' ');
});

const iconSize = computed(() => {
  if (props.size === 'sm') return 16;
  if (props.size === 'lg') return 20;
  return 18;
});

const handleClick = e => {
  emit('click', e);
};
</script>

<template>
  <button
    :class="buttonClasses"
    :type="type"
    class="inline-flex items-center justify-center min-w-0 gap-2 text-sm font-medium transition-all duration-200 ease-in-out rounded-lg disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50"
    @click="handleClick"
  >
    <FluentIcon
      v-if="icon && iconPosition === 'left' && !isLoading"
      :icon="icon"
      :size="iconSize"
      :icon-lib="iconLib"
      class="flex-shrink-0"
      :class="{
        'text-n-slate-11 dark:text-n-slate-11': variant === 'secondary',
      }"
    />
    <Spinner v-if="isLoading" class="!w-5 !h-5 flex-shrink-0" />
    <slot name="leftPrefix" />
    <span v-if="emoji">{{ emoji }}</span>
    <span v-if="label" class="min-w-0 truncate">{{ label }}</span>
    <slot />
    <slot name="rightPrefix" />
    <FluentIcon
      v-if="icon && iconPosition === 'right'"
      :icon="icon"
      :size="iconSize"
      :icon-lib="iconLib"
      class="flex-shrink-0"
      :class="{
        'text-n-slate-11 dark:text-n-slate-11': variant === 'secondary',
      }"
    />
  </button>
</template>
