<script setup>
import { computed } from 'vue';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants';

const props = defineProps({
  variant: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_VARIANTS).includes(value),
  },
  orientation: {
    type: String,
    required: true,
    validator: value => Object.values(ORIENTATION).includes(value),
  },
  content: {
    type: String,
    required: true,
  },
});

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-n-solid-blue p-3 text-n-slate-12',
  [MESSAGE_VARIANTS.PRIVATE]: 'bg-n-solid-amber p-3 text-n-amber-12',
  [MESSAGE_VARIANTS.USER]: 'bg-n-slate-4 p-3 text-n-slate-12',
  [MESSAGE_VARIANTS.ACTIVITY]:
    'bg-n-alpha-1 px-2 py-0.5 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]: 'bg-n-teal-5 p-3 text-n-slate-12',
  [MESSAGE_VARIANTS.TEMPLATE]: 'bg-n-teal-5 p-3 text-n-slate-12',
};

const orientationMap = {
  left: 'rounded-xl rounded-bl-sm',
  right: 'rounded-xl rounded-br-sm',
};

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[props.variant]];

  if (props.variant !== 'system') {
    classToApply.push(orientationMap[props.orientation]);
  } else {
    classToApply.push('rounded-lg');
  }

  return classToApply;
});
</script>

<template>
  <div class="max-w-md text-sm" :class="messageClass">
    {{ content }}
  </div>
</template>
