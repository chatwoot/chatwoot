<script setup>
defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
  loadingMessage: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <div class="flex flex-col w-full h-full gap-10 font-inter">
    <slot name="header" />
    <div>
      <slot v-if="isLoading" name="loading">
        <woot-loading-state :message="loadingMessage" />
      </slot>
      <slot v-else name="body" />
    </div>
  </div>
</template>
