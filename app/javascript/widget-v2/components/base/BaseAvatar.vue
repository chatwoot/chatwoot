<script setup>
import { computed, ref } from 'vue';

const props = defineProps({
  src: { type: String, default: '' },
  name: { type: String, default: '' },
  size: { type: Number, default: 32 },
});

const imageFailed = ref(false);

const initials = computed(() =>
  (props.name || '?')
    .split(' ')
    .slice(0, 2)
    .map(part => part.charAt(0))
    .join('')
    .toUpperCase()
);

const showImage = computed(() => props.src && !imageFailed.value);
</script>

<template>
  <span
    class="avatar-shape inline-flex items-center justify-center shrink-0 overflow-hidden bg-cw-muted text-cw-text-muted font-medium"
    :style="{
      width: `${size}px`,
      height: `${size}px`,
      fontSize: `${size * 0.38}px`,
    }"
  >
    <img
      v-if="showImage"
      :src="src"
      :alt="name"
      class="w-full h-full object-cover"
      @error="imageFailed = true"
    />
    <span v-else>{{ initials }}</span>
  </span>
</template>
