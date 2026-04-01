<script setup>
import { ref, watch } from 'vue';
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

const resetConversation = () => {
  messages.value = [];
  newMessage.value = '';
};

// Watch for assistant ID changes and reset conversation
watch(
  () => assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
    }
  }
);

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
    class="group/cardLayout relative flex h-full flex-col overflow-hidden rounded-xl border border-outline-variant/10 bg-surface-container-low shadow-sm"
  >
    <div
      class="pointer-events-none absolute inset-0 bg-gradient-to-b from-surface-container-low/40 via-surface to-surface"
    />
    <div
      class="relative mx-6 mt-4 mb-2 flex items-start justify-between rounded-xl border border-outline-variant/10 bg-surface/40 px-4 py-3"
    >
      <div>
        <h3 class="text-lg font-semibold tracking-tight text-on-surface">
          {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
        </h3>
        <p class="mt-0.5 text-xs text-on-surface-variant">
          {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
        </p>
      </div>
      <NextButton
        xs
        outline
        teal
        icon="i-lucide-rotate-ccw"
        :label="t('CAPTAIN.COPILOT.RESET')"
        @click="resetConversation"
      />
    </div>

    <MessageList
      :messages="messages"
      :is-loading="isLoading"
      class="relative"
    />

    <div class="relative px-6 pb-5 pt-2">
      <div
        class="flex items-center gap-3 rounded-2xl border border-secondary/35 bg-surface-container-lowest/90 px-4 py-2 shadow-lg shadow-black/20 focus-within:border-secondary/80 focus-within:ring-2 focus-within:ring-secondary/25"
      >
        <input
          v-model="newMessage"
          class="mb-0 min-w-0 flex-1 border-none bg-transparent text-base text-on-surface placeholder:text-on-surface-variant/70 focus:!outline-none focus:!ring-0"
          :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
          @keyup.enter="sendMessage"
        />
        <NextButton
          sm
          teal
          :disabled="!newMessage.trim()"
          icon="i-lucide-send"
          @click="sendMessage"
        />
      </div>
    </div>
  </div>
</template>
