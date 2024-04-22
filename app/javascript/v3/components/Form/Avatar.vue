<template>
  <div
    class="rounded-xl flex leading-[100%] font-medium items-center justify-center text-center cursor-default"
    :class="`h-[${size}px] w-[${size}]px ${colorClass}`"
    :style="style"
    aria-hidden="true"
  >
    <slot>{{ userInitial }}</slot>
  </div>
</template>

<script setup>
import { computed } from 'vue';

const colors = {
  1: 'bg-ash-200 text-ash-900',
  2: 'bg-amber-200 text-amber-900',
};

const props = defineProps({
  username: {
    type: String,
    default: '',
  },
  size: {
    type: Number,
    default: 72,
  },
});

const style = computed(() => ({
  fontSize: `${Math.floor(props.size / 2.5)}px`,
}));

const colorClass = computed(() => {
  return colors[(props.username.length % 2) + 1];
});

const userInitial = computed(() => {
  const parts = props.username.split(/[ -]/).filter(Boolean);
  let initials = parts.map(part => part[0].toUpperCase()).join('');
  return initials.slice(0, 2);
});
</script>
