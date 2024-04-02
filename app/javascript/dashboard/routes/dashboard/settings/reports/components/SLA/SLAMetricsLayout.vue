<script setup>
defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>
<template>
  <div class="flex flex-col gap-2 items-start justify-center min-w-[10rem]">
    <slot name="label" />
    <slot v-if="isLoading" name="loading" />
    <slot v-else name="value" />
  </div>
</template>
