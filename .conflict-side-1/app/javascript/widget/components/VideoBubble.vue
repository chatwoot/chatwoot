<script setup>
defineProps({
  url: { type: String, default: '' },
  readableTime: { type: String, default: '' },
});

const emit = defineEmits(['error']);

const onVideoError = () => {
  emit('error');
};
</script>

<template>
  <div class="relative block max-w-full">
    <video
      class="w-full max-w-[250px] h-auto"
      :src="url"
      controls
      @error="onVideoError"
    />
    <span
      class="absolute text-xs text-white dark:text-white right-3 bottom-1 whitespace-nowrap"
    >
      {{ readableTime }}
    </span>
  </div>
</template>
