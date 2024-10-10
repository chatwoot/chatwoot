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
  iconLib: {
    type: String,
    default: 'fluent',
  },
});

const emit = defineEmits(['click']);

const buttonVariants = {
  variant: {
    default:
      'bg-woot-500 dark:bg-woot-500 text-white dark:text-white hover:bg-woot-600 dark:hover:bg-woot-600',
    destructive:
      'bg-ruby-700 dark:bg-ruby-700 text-white dark:text-white hover:bg-ruby-800 dark:hover:bg-ruby-800',
    outline:
      'border border-slate-200 dark:border-slate-700/50 hover:border-slate-300 dark:hover:border-slate-600',
    secondary:
      'bg-slate-50 text-slate-900 dark:bg-slate-700/50 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-600',
    ghost:
      'text-slate-900 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800',
    link: 'text-woot-500 underline-offset-4 hover:underline dark:hover:underline',
  },
  size: {
    default: 'h-10 px-4 py-2',
    sm: 'h-8 px-3',
    lg: 'h-11 px-4',
    icon: 'h-auto w-auto px-2',
  },
  text: {
    default:
      '!text-woot-500 dark:!text-woot-500 hover:!text-woot-600 dark:hover:!text-woot-600',
    success:
      '!text-green-500 dark:!text-green-500 hover:!text-green-600 dark:hover:!text-green-600',
    warning:
      '!text-amber-600 dark:!text-amber-600 hover:!text-amber-600 dark:hover:!text-amber-600',
    danger:
      '!text-ruby-700 dark:!text-ruby-700 hover:!text-ruby-800 dark:hover:!text-ruby-800',
    info: '!text-slate-500 dark:!text-slate-400 hover:!text-slate-600 dark:hover:!text-slate-500',
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
    class="inline-flex items-center justify-center h-10 min-w-0 gap-2 text-sm font-medium transition-all duration-200 ease-in-out rounded-lg disabled:cursor-not-allowed disabled:pointer-events-none disabled:opacity-50"
    @click="handleClick"
  >
    <FluentIcon
      v-if="icon && iconPosition === 'left'"
      :icon="icon"
      :size="iconSize"
      :icon-lib="iconLib"
      class="flex-shrink-0"
    />
    <span v-if="label" class="min-w-0 truncate">{{ label }}</span>
    <FluentIcon
      v-if="icon && iconPosition === 'right'"
      :icon="icon"
      :size="iconSize"
      :icon-lib="iconLib"
      class="flex-shrink-0"
    />
  </button>
</template>
