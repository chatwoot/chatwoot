<script setup>
import { ref, computed } from 'vue';
import { useMessageContext } from '../provider.js';
import Icon from 'next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../constants';

const emit = defineEmits(['error']);
const { variant, content, attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
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
      v-if="!hasImgStoryError"
      class="rounded-lg max-w-80 skip-context-menu"
      :src="attachment.dataUrl"
      @error="onImageLoadError"
    />
    <video
      v-else-if="!hasVideoStoryError"
      class="rounded-lg max-w-80 skip-context-menu"
      controls
      :src="attachment.dataUrl"
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
