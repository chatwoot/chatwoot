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
</script>

<template>
  <div
    class="flex gap-2 px-4"
    :class="isVisitor ? 'justify-end' : 'justify-start'"
  >
    <BaseAvatar
      v-if="!isVisitor && showMeta"
      :src="message.sender?.avatar_url"
      :name="senderName"
      :size="24"
      class="mt-auto mb-5"
    />
    <div v-else-if="!isVisitor" class="w-6 shrink-0" />

    <div class="max-w-[80%] min-w-0">
      <div
        class="px-3.5 py-2.5 text-sm leading-relaxed break-words rounded-token"
        :class="
          isVisitor
            ? 'bg-cw-primary text-cw-primary-foreground rounded-br-md'
            : 'bg-cw-muted text-cw-text rounded-bl-md'
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
            class="max-w-full rounded-token-sm"
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
            <span class="i-lucide-paperclip" />
            {{ attachment.data_url?.split('/').pop() }}
          </a>
        </div>
        <div
          v-if="message.content"
          v-dompurify-html="formattedContent"
          class="prose prose-bubble [&_a]:underline"
          :class="isVisitor ? '[&_*]:!text-cw-primary-foreground' : ''"
        />
      </div>

      <div
        v-if="showMeta"
        class="flex items-center gap-1.5 mt-1 text-xxs text-cw-text-faint"
        :class="isVisitor ? 'justify-end' : 'justify-start'"
      >
        <span
          v-if="isFromAi"
          class="inline-flex items-center gap-0.5 font-medium text-cw-primary"
        >
          <span class="i-lucide-sparkles" />
          {{ $t('AI_STATE.AI_DEFAULT_NAME') }}
        </span>
        <span v-else-if="!isVisitor && senderName" class="font-medium">
          {{ senderName }}
        </span>
        <span v-if="isFailed" class="text-red-500">
          {{ $t('CONVERSATION.SEND_FAILED') }}
        </span>
        <span v-else>{{ formatTime(message.created_at) }}</span>
      </div>
    </div>
  </div>
</template>
