<script setup>
import { ref, computed } from 'vue';
import { useMessageContext } from '../provider.js';
import Icon from 'next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../constants';

const emit = defineEmits(['error']);
const { variant, content, attachments, contentAttributes } =
  useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

// For shared content and story replies, use the URL from content_attributes
const mediaUrl = computed(() => {
  if (attachment.value) {
    return attachment.value.dataUrl;
  }
  // Handle shared content case
  if (contentAttributes.value?.sharedContentUrl) {
    return contentAttributes.value.sharedContentUrl;
  }
  // Handle story reply case
  return contentAttributes.value?.storyUrl;
});

const hasImgStoryError = ref(false);
const hasVideoStoryError = ref(false);

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return content.value;
  }

  return new MessageFormatter(content.value).formattedMessage;
});

const onImageLoadError = () => {
  hasImgStoryError.value = true;
  emit('error');
};

const onVideoLoadError = () => {
  hasVideoStoryError.value = true;
  emit('error');
};
</script>

<template>
  <BaseBubble class="p-3 overflow-hidden" data-bubble-name="ig-story">
    <div v-if="content" v-dompurify-html="formattedContent" class="mb-2" />
    <img
      v-if="!hasImgStoryError && mediaUrl"
      class="rounded-lg max-w-80 skip-context-menu"
      :src="mediaUrl"
      @error="onImageLoadError"
    />
    <video
      v-else-if="!hasVideoStoryError && mediaUrl"
      class="rounded-lg max-w-80 skip-context-menu"
      controls
      :src="mediaUrl"
      @error="onVideoLoadError"
    />
    <div
      v-else
      class="flex items-center gap-1 px-5 py-4 text-center rounded-lg bg-n-alpha-1"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.FILE_BUBBLE.INSTAGRAM_STORY_UNAVAILABLE') }}
      </p>
    </div>
  </BaseBubble>
</template>
