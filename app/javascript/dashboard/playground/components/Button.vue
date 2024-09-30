<script setup>
import { computed } from 'vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

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
    validator: value => ['default', 'sm', 'lg', 'icon'].includes(value),
  },
  icon: {
    type: String,
    default: '',
  },
  iconPosition: {
    type: String,
    default: 'left',
    validator: value => ['left', 'right'].includes(value),
  },
});

const emit = defineEmits(['click']);

const buttonVariants = {
  variant: {
    default:
      'bg-woot-500 dark:bg-woot-500 hover:opacity-95 text-white dark:text-white dark:hover:opacity-95',
    destructive:
      'bg-ruby-700 dark:bg-ruby-600 text-white dark:text-white hover:opacity-95 dark:hover:opacity-95',
    outline:
      'border border-slate-200 dark:border-slate-700/50 bg-white dark:bg-slate-900 dark:hover:bg-slate-900 hover:bg-white hover:text-slate-500 hover:opacity-95 dark:hover:opacity-95',
    secondary:
      'bg-slate-50 text-slate-900 dark:bg-slate-700/50 dark:text-slate-100 hover:opacity-95 dark:hover:opacity-95',
    ghost:
      'text-slate-900 dark:text-slate-200 hover:opacity-95 dark:hover:opacity-95',
    link: 'text-woot-500 underline-offset-4 hover:underline hover:opacity-95 dark:hover:opacity-95',
  },
  size: {
    default: 'h-10 px-4 py-2',
    sm: 'h-8 rounded-md px-3',
    lg: 'h-11 rounded-md px-8',
    icon: 'h-auto w-auto px-2',
  },
  text: {
    default: '',
    success:
      '!text-green-500 dark:!text-green-500 hover:!text-green-600 dark:hover:!text-green-600',
    warning:
      '!text-amber-500 dark:!text-amber-500 hover:!text-amber-600 dark:hover:!text-amber-600',
    danger:
      '!text-ruby-700 dark:!text-ruby-700 hover:!text-ruby-600 dark:hover:!text-ruby-600',
    info: '!text-woot-500 dark:!text-woot-500 hover:!text-woot-600 dark:hover:!text-woot-600',
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

const handleClick = () => {
  emit('click');
};
</script>

<template>
  <button
    :class="buttonClasses"
    class="inline-flex items-center justify-center h-10 gap-2 text-sm font-medium transition-colors rounded-lg ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
    @click="handleClick"
  >
    <FluentIcon
      v-if="icon && iconPosition === 'left'"
      :icon="icon"
      :size="iconSize"
    />
    <span v-if="label" class="line-clamp-1">{{ label }}</span>
    <FluentIcon
      v-if="icon && iconPosition === 'right'"
      :icon="icon"
      :size="iconSize"
    />
  </button>
</template>
