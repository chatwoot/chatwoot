<script setup>
import { useI18n } from 'vue-i18n';
import { ref, watch, nextTick } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
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

const getAvatarName = sender =>
  isUserMessage(sender)
    ? t('CAPTAIN.PLAYGROUND.USER')
    : t('CAPTAIN.PLAYGROUND.ASSISTANT');

const getMessageStyle = sender =>
  isUserMessage(sender)
    ? 'bg-n-strong text-n-white'
    : 'bg-n-solid-iris text-n-slate-12';

const scrollToBottom = async () => {
  await nextTick();
  if (messageContainer.value) {
    messageContainer.value.scrollTop = messageContainer.value.scrollHeight;
  }
};

watch(() => props.messages.length, scrollToBottom);
</script>

<template>
  <div ref="messageContainer" class="flex-1 overflow-y-auto mb-4 space-y-2">
    <div
      v-for="(message, index) in messages"
      :key="index"
      class="flex"
      :class="getMessageAlignment(message.sender)"
    >
      <div
        class="flex items-start gap-1.5"
        :class="getMessageDirection(message.sender)"
      >
        <Avatar :name="getAvatarName(message.sender)" rounded-full :size="24" />
        <div
          class="max-w-[80%] rounded-lg p-3 text-sm"
          :class="getMessageStyle(message.sender)"
        >
          <div class="break-words" v-html="formatMessage(message.content)" />
        </div>
      </div>
    </div>
    <div v-if="isLoading" class="flex justify-start">
      <div class="flex items-start gap-1.5">
        <Avatar :name="getAvatarName('assistant')" rounded-full :size="24" />
        <div
          class="max-w-sm rounded-lg p-3 text-sm bg-n-solid-iris text-n-slate-12"
        >
          <div class="flex gap-1">
            <div class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce" />
            <div
              class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce [animation-delay:0.2s]"
            />
            <div
              class="w-2 h-2 rounded-full bg-n-iris-10 animate-bounce [animation-delay:0.4s]"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
