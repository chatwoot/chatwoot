<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MessageList from './MessageList.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const { assistantId } = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);

const formatMessagesForApi = () => {
  return messages.value.map(message => ({
    role: message.sender,
    content: message.content,
  }));
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || isLoading.value) return;

  const userMessage = {
    content: newMessage.value,
    sender: 'user',
    timestamp: new Date().toISOString(),
  };
  messages.value.push(userMessage);
  const currentMessage = newMessage.value;
  newMessage.value = '';

  try {
    isLoading.value = true;
    const { data } = await CaptainAssistant.playground({
      assistantId,
      messageContent: currentMessage,
      messageHistory: formatMessagesForApi(),
    });

    messages.value.push({
      content: data.response,
      sender: 'assistant',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error getting assistant response:', error);
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col h-full rounded-lg p-4 outline outline-n-container text-n-slate-11"
  >
    <div class="mb-4">
      <h3 class="text-lg font-medium mb-1">
        {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
      </h3>
      <p class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
      </p>
    </div>

    <MessageList :messages="messages" :is-loading="isLoading" />

    <div
      class="flex items-center bg-white outline outline-n-container rounded-lg p-3"
    >
      <input
        v-model="newMessage"
        class="flex-1 bg-transparent border-none focus:outline-none text-sm mb-0"
        :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
        @keyup.enter="sendMessage"
      />
      <NextButton
        ghost
        size="small"
        :disabled="!newMessage.trim()"
        icon="i-lucide-send"
        @click="sendMessage"
      />
    </div>

    <p class="text-xs text-n-slate-11 pt-2 text-center">
      {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
    </p>
  </div>
</template>
