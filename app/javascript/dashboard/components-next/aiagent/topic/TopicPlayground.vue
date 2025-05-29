<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MessageList from './MessageList.vue';
import AiagentTopic from 'dashboard/api/aiagent/topic';

const { topicId } = defineProps({
  topicId: {
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

const resetConversation = () => {
  messages.value = [];
  newMessage.value = '';
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
    const { data } = await AiagentTopic.playground({
      topicId,
      messageContent: currentMessage,
      messageHistory: formatMessagesForApi(),
    });

    messages.value.push({
      content: data.response,
      sender: 'topic',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error getting topic response:', error);
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col h-full rounded-lg p-4 border border-n-slate-4 text-n-slate-11"
  >
    <div class="mb-4">
      <div class="flex justify-between items-center mb-1">
        <h3 class="text-lg font-medium">
          {{ t('AIAGENT.PLAYGROUND.HEADER') }}
        </h3>
        <NextButton
          ghost
          size="small"
          icon="i-lucide-rotate-ccw"
          @click="resetConversation"
        />
      </div>
      <p class="text-sm text-n-slate-11">
        {{ t('AIAGENT.PLAYGROUND.DESCRIPTION') }}
      </p>
    </div>

    <MessageList :messages="messages" :is-loading="isLoading" />

    <div
      class="flex items-center bg-n-solid-1 outline outline-n-container rounded-lg p-3"
    >
      <input
        v-model="newMessage"
        class="flex-1 bg-transparent border-none focus:outline-none text-sm mb-0"
        :placeholder="t('AIAGENT.PLAYGROUND.MESSAGE_PLACEHOLDER')"
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
      {{ t('AIAGENT.PLAYGROUND.CREDIT_NOTE') }}
    </p>
  </div>
</template>
