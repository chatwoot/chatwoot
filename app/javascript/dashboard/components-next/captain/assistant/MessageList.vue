<script setup>
import { ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  messages: {
    type: Array,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const messageContainer = ref(null);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const isUserMessage = sender => sender === 'user';

const getMessageAlignment = sender =>
  isUserMessage(sender) ? 'justify-end' : 'justify-start';

const getMessageDirection = sender =>
  isUserMessage(sender) ? 'flex-row-reverse' : 'flex-row';

const getMessageStyle = sender =>
  isUserMessage(sender)
    ? 'bg-secondary text-on-secondary rounded-2xl rounded-tr-md shadow-[0_8px_20px_rgba(6,190,153,0.25)]'
    : 'bg-surface-container text-on-surface rounded-2xl rounded-tl-md border border-outline-variant/10';

const getAvatarInitial = sender => {
  const label = isUserMessage(sender)
    ? t('CAPTAIN.PLAYGROUND.USER')
    : t('CAPTAIN.PLAYGROUND.ASSISTANT');
  return label.charAt(0).toUpperCase();
};

const scrollToBottom = async () => {
  await nextTick();
  if (messageContainer.value) {
    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
  }
};

watch(() => props.messages.length, scrollToBottom);
</script>

<template>
  <div
    ref="messageContainer"
    class="scrollbar-thin flex-1 space-y-14 overflow-y-auto px-6 pb-6 pt-2"
  >
    <div
      v-for="(message, index) in messages"
      :key="index"
      class="flex"
      :class="getMessageAlignment(message.sender)"
    >
      <div
        class="flex items-center gap-2 max-w-[90%] md:max-w-[45%]"
        :class="getMessageDirection(message.sender)"
      >
        <span
          class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[10px] font-semibold uppercase"
          :class="
            isUserMessage(message.sender)
              ? 'bg-surface-container-low text-secondary'
              : 'bg-secondary/10 text-secondary'
          "
        >
          {{ getAvatarInitial(message.sender) }}
        </span>
        <div
          class="px-4 py-3 text-[1.05rem] leading-tight [overflow-wrap:break-word]"
          :class="getMessageStyle(message.sender)"
        >
          <div v-html="formatMessage(message.content)" />
        </div>
      </div>
    </div>
    <div v-if="isLoading" class="flex justify-start">
      <div class="flex items-center gap-2">
        <span
          class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-secondary/10 text-[10px] font-semibold uppercase text-secondary"
        >
          {{ getAvatarInitial('assistant') }}
        </span>
        <div
          class="max-w-sm rounded-2xl rounded-tl-md border border-outline-variant/10 bg-surface-container p-3 text-sm text-on-surface"
        >
          <div class="flex gap-1">
            <div class="h-2 w-2 animate-bounce rounded-full bg-secondary" />
            <div
              class="h-2 w-2 animate-bounce rounded-full bg-secondary [animation-delay:0.2s]"
            />
            <div
              class="h-2 w-2 animate-bounce rounded-full bg-secondary [animation-delay:0.4s]"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
