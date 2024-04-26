<template>
  <div
    class="rounded-xl flex leading-[100%] font-medium items-center justify-center text-center cursor-default"
    :class="`h-[${size}px] w-[${size}px] ${colorClass}`"
    :style="style"
    aria-hidden="true"
  >
    <slot>{{ initial }}</slot>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { userInitial } from 'v3/helpers/CommonHelper';
const colors = {
  1: 'bg-ash-200 text-ash-900',
  2: 'bg-amber-200 text-amber-900',
  3: 'bg-pink-100 text-pink-800',
  4: 'bg-purple-100 text-purple-800',
  5: 'bg-indigo-100 text-indigo-800',
  6: 'bg-grass-100 text-grass-800',
  7: 'bg-mint-100 text-mint-800',
  8: 'bg-orange-100 text-orange-800',
};
const props = defineProps({
  name: {
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
  return colors[(props.name.length % 8) + 1];
});

const initial = computed(() => userInitial(props.name));
</script>
