<script setup>
defineProps({
  url: { type: String, default: '' },
  readableTime: { type: String, default: '' },
});

const emits = defineEmits(['error']);

const onVideoError = () => {
  emits('error');
};
</script>
<template>
  <div class="block relative max-w-full">
    <video
      class="w-full max-w-[250px] h-auto"
      :src="url"
      controls
      @error="onVideoError"
    />
    <span
      class="text-xs absolute text-white dark:text-white right-3 bottom-1 whitespace-nowrap"
    >
      {{ readableTime }}
    </span>
  </div>
</template>
