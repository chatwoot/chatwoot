<script setup>
import { computed } from 'vue';
const props = defineProps({
  variant: {
    type: String,
    required: true,
    validator: value => ['user', 'agent', 'system', 'private'].includes(value),
  },
  orientation: {
    type: String,
    default: 'left',
    validator: value => ['left', 'right', 'center'].includes(value),
  },
  text: {
    type: String,
    default: 'Hello World',
  },
});

const varaintBaseMap = {
  agent: 'bg-n-solid-blue p-3 text-n-slate-12',
  private: 'bg-n-solid-amber p-3 text-n-amber-12',
  user: 'bg-n-slate-4 p-3 text-n-slate-12',
  system: 'bg-n-alpha-1 px-2 py-0.5 text-n-slate-11 text-sm',
};

const orientationMap = {
  left: 'rounded-xl rounded-bl-sm',
  right: 'rounded-xl rounded-br-sm',
};

const containetFlexJustify = computed(() => {
  const map = {
    left: 'justify-start',
    right: 'justify-end',
    center: 'justify-center',
  };

  return map[props.orientation];
});

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
  <div class="flex w-full" :class="containetFlexJustify">
    <div class="max-w-md text-sm" :class="messageClass">
      {{ text }}
    </div>
  </div>
</template>
