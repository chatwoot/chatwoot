<script setup>
import { ref, computed } from 'vue';
import { useMessageContext } from '../provider.js';
import Icon from 'next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { MESSAGE_VARIANTS } from '../constants';

/**
 * @typedef {Object} Attachment
 * @property {number} id - Unique identifier for the attachment
 * @property {number} messageId - ID of the associated message
 * @property {'image'|'audio'|'video'|'file'|'location'|'fallback'|'share'|'story_mention'|'contact'|'ig_reel'} fileType - Type of the attachment (file or image)
 * @property {number} accountId - ID of the associated account
 * @property {string|null} extension - File extension
 * @property {string} dataUrl - URL to access the full attachment data
 * @property {string} thumbUrl - URL to access the thumbnail version
 * @property {number} fileSize - Size of the file in bytes
 * @property {number|null} width - Width of the image if applicable
 * @property {number|null} height - Height of the image if applicable
 */
const props = defineProps({
  content: {
    type: String,
    required: true,
  },
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['error']);

const attachment = computed(() => {
  return props.attachments[0];
});

const { variant } = useMessageContext();
const hasImgStoryError = ref(false);
const hasVideoStoryError = ref(false);

const formattedContent = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.ACTIVITY) {
    return props.content;
  }

  return new MessageFormatter(props.content).formattedMessage;
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
    <div v-if="content" class="mb-2" v-html="formattedContent" />
    <img
      v-if="!hasImgStoryError"
      class="rounded-lg max-w-80"
      :src="attachment.dataUrl"
      @error="onImageLoadError"
    />
    <video
      v-else-if="!hasVideoStoryError"
      class="rounded-lg max-w-80"
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
