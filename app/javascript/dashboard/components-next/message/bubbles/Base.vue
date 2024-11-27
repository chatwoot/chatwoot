<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_VARIANTS } from '../constants';

const { variant, orientation } = useMessageContext();

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-n-solid-blue text-n-slate-12',
  [MESSAGE_VARIANTS.PRIVATE]: 'bg-n-solid-amber text-n-amber-12',
  [MESSAGE_VARIANTS.USER]: 'bg-n-slate-4 text-n-slate-12',
  [MESSAGE_VARIANTS.ACTIVITY]: 'bg-n-alpha-1 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]: 'bg-n-teal-5 text-n-slate-12',
  [MESSAGE_VARIANTS.TEMPLATE]: 'bg-n-teal-5 text-n-slate-12',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12',
};

const orientationMap = {
  left: 'rounded-xl rounded-bl-sm',
  right: 'rounded-xl rounded-br-sm',
  center: 'rounded-md',
};

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[variant.value]];

  if (variant.value !== MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push(orientationMap[orientation.value]);
  } else {
    classToApply.push('rounded-lg');
  }

  return classToApply;
});
</script>

<template>
  <div class="max-w-md text-sm" :class="messageClass">
    <slot />
  </div>
</template>
