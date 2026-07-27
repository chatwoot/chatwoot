<script setup>
defineProps({
  size: { type: Number, default: 20 },
});
</script>

<template>
  <span
    class="inline-block animate-spin rounded-full border-2 border-cw-border border-t-cw-primary"
    :style="{ width: `${size}px`, height: `${size}px` }"
    role="status"
  />
</template>
