<script setup>
import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import { nextTick, ref, watch } from 'vue';

const props = defineProps({
  supportAgent: {
    type: Object,
    default: () => ({}),
  },
  messages: {
    type: Array,
    default: () => [],
  },
  isCaptainTyping: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['sendMessage']);

const COPILOT_USER_ROLES = ['assistant', 'system'];

const sendMessage = message => {
  emit('sendMessage', message);
};
const chatContainer = ref(null);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

watch(
  [() => props.messages, () => props.isCaptainTyping],
  () => {
    scrollToBottom();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col ]mx-auto h-full text-sm leading-6 tracking-tight">
    <div ref="chatContainer" class="flex-1 overflow-y-auto py-4 space-y-6 px-4">
      <template v-for="message in messages" :key="message.id">
        <CopilotAgentMessage
          v-if="message.role === 'user'"
          :support-agent="supportAgent"
          :message="message"
        />
        <CopilotAssistantMessage
          v-else-if="COPILOT_USER_ROLES.includes(message.role)"
          :message="message"
        />
      </template>

      <CopilotLoader v-if="isCaptainTyping" />
    </div>

    <CopilotInput class="mx-3 mb-4 mt-px" @send="sendMessage" />
  </div>
</template>
