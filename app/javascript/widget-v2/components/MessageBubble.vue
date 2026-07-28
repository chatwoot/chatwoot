<script setup>
import { computed } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { formatTime } from 'widget-v2/helpers/time';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const props = defineProps({
  message: { type: Object, required: true },
  showMeta: { type: Boolean, default: true },
});

const { formatMessage } = useMessageFormatter();

const isVisitor = computed(() => props.message.message_type === 0);
const isFromAi = computed(
  () => props.message.sender?.type === 'captain_assistant'
);
const senderName = computed(
  () => props.message.sender?.available_name || props.message.sender?.name || ''
);
const formattedContent = computed(() =>
  formatMessage(props.message.content || '', false)
);
const attachments = computed(() => props.message.attachments || []);
const isFailed = computed(() => props.message.status === 'failed');

// Attachments carry the stored dimensions, so the box can be reserved before
// the image decodes — otherwise the thread grows underneath the visitor and
// pushes the newest message out of view. Very tall images are clamped so a
// portrait screenshot can't fill the whole panel.
const MIN_ASPECT_RATIO = 0.62;

const aspectRatio = attachment => {
  const { width, height } = attachment;
  if (!width || !height) return null;
  return Math.max(width / height, MIN_ASPECT_RATIO);
};
</script>

<template>
  <div
    class="flex gap-2 px-5"
    :class="isVisitor ? 'justify-end' : 'justify-start'"
  >
    <BaseAvatar
      v-if="!isVisitor && showMeta"
      :src="message.sender?.avatar_url"
      :name="senderName"
      :size="26"
      class="mt-auto mb-6"
    />
    <div v-else-if="!isVisitor" class="w-[26px] shrink-0" />

    <div class="max-w-[78%] min-w-0">
      <div
        class="px-4 py-2.5 text-sm leading-relaxed break-words rounded-bubble"
        :class="
          isVisitor
            ? 'bubble-visitor rounded-bubble-tail-end'
            : 'bubble-agent rounded-bubble-tail-start'
        "
      >
        <div
          v-for="attachment in attachments"
          :key="attachment.id"
          class="mb-1 last:mb-0"
        >
          <img
            v-if="attachment.file_type === 'image'"
            :src="attachment.data_url"
            :width="attachment.width || undefined"
            :height="attachment.height || undefined"
            :style="
              aspectRatio(attachment)
                ? { aspectRatio: String(aspectRatio(attachment)) }
                : null
            "
            class="w-full max-w-full object-cover rounded-token-sm bg-cw-muted"
            decoding="async"
            :alt="attachment.extension || 'attachment'"
          />
          <audio
            v-else-if="attachment.file_type === 'audio'"
            controls
            class="max-w-full"
          >
            <source :src="attachment.data_url" />
          </audio>
          <a
            v-else
            :href="attachment.data_url"
            target="_blank"
            rel="noreferrer noopener"
            class="inline-flex items-center gap-1.5 underline"
          >
            <span class="i-ph-paperclip" />
            {{ attachment.data_url?.split('/').pop() }}
          </a>
        </div>
        <div
          v-if="message.content"
          v-dompurify-html="formattedContent"
          class="prose prose-bubble bubble-prose [&_a]:underline"
        />
      </div>

      <div
        v-if="showMeta"
        class="flex items-center gap-1.5 mt-1.5 px-1 text-xs text-cw-text-faint tabular-time"
        :class="isVisitor ? 'justify-end' : 'justify-start'"
      >
        <span
          v-if="isFromAi"
          class="ai-accent inline-flex items-center gap-0.5 font-medium"
        >
          <span class="i-ph-sparkle" />
          {{ $t('AI_STATE.AI_DEFAULT_NAME') }}
        </span>
        <span v-else-if="!isVisitor && senderName" class="font-medium">
          {{ senderName }}
        </span>
        <span v-if="isFailed" class="text-n-ruby-11">
          {{ $t('CONVERSATION.SEND_FAILED') }}
        </span>
        <span v-else>{{ formatTime(message.created_at) }}</span>
      </div>
    </div>
  </div>
</template>
