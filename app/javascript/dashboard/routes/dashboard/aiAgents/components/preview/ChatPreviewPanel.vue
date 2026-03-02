<script setup>
import { ref, nextTick, computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAgentPreview } from '../../composables/useAgentPreview';
import ChatPreviewMessage from './ChatPreviewMessage.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();

const agentRef = toRef(props, 'agent');

const { messages, isStreaming, sendPreviewMessage, restart } =
  useAgentPreview(agentRef);

const userInput = ref('');
const chatContainer = ref(null);

const isEmpty = computed(
  () => messages.value.filter(m => m.role !== 'system').length === 0
);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const handleSend = async () => {
  const content = userInput.value.trim();
  if (!content || isStreaming.value) return;

  userInput.value = '';
  await sendPreviewMessage(content);
  scrollToBottom();
};

const handleKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    handleSend();
  }
};

const handleRestart = () => {
  restart();
};
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
    >
      <div class="flex items-center gap-2">
        <span class="i-lucide-message-square size-4 text-n-slate-10" />
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ t('AI_AGENTS.PREVIEW.TITLE') }}
        </h3>
      </div>
      <div class="flex items-center gap-1">
        <Button
          v-if="!isEmpty"
          icon="i-lucide-rotate-ccw"
          variant="ghost"
          color="slate"
          size="xs"
          :label="t('AI_AGENTS.PREVIEW.RESTART')"
          @click="handleRestart"
        />
      </div>
    </div>

    <!-- Messages -->
    <div
      ref="chatContainer"
      class="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3"
    >
      <!-- Empty state -->
      <div
        v-if="isEmpty"
        class="flex flex-col items-center justify-center h-full gap-3 text-center"
      >
        <div
          class="flex items-center justify-center size-12 rounded-2xl bg-n-alpha-2"
        >
          <span class="i-lucide-bot size-6 text-n-slate-10" />
        </div>
        <p class="text-sm text-n-slate-10 max-w-xs">
          {{ t('AI_AGENTS.PREVIEW.EMPTY') }}
        </p>
      </div>

      <!-- Message list -->
      <template v-for="msg in messages" :key="msg.id">
        <ChatPreviewMessage
          v-if="msg.role !== 'system'"
          :role="msg.role"
          :content="msg.content"
          :is-streaming="msg.streaming"
          :is-error="!!msg.error"
        />
      </template>
    </div>

    <!-- Input -->
    <div class="flex items-end gap-2 px-4 py-3 border-t border-n-weak">
      <textarea
        v-model="userInput"
        :placeholder="t('AI_AGENTS.PREVIEW.INPUT_PLACEHOLDER')"
        rows="1"
        class="flex-1 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-7 resize-none"
        :disabled="isStreaming"
        @keydown="handleKeydown"
      />
      <Button
        icon="i-lucide-send"
        size="sm"
        :disabled="isStreaming || !userInput.trim()"
        @click="handleSend"
      />
    </div>
  </div>
</template>
