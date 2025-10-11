<script setup>
import { captureSentryException } from '../helpers/sentry';

const props = defineProps({
  url: { type: String, default: '' },
  readableTime: { type: String, default: '' },
});

const emit = defineEmits(['error']);

const onVideoError = () => {
  // Log video attachment failure to Sentry (lazy-loaded)
  captureSentryException(new Error('Widget: Video attachment failed to load'), {
    level: 'warning',
    tags: {
      component: 'VideoBubble',
      error_type: 'attachment_download_failure',
    },
    extra: {
      videoUrl: props.url,
      timestamp: props.readableTime,
    },
  });
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
