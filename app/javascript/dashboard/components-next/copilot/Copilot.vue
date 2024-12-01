<script setup>
import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';

defineProps({
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
const sendMessage = message => {
  emit('sendMessage', message);
};
</script>

<template>
  <div class="flex flex-col bg-n-solid-2 max-w-96 mx-auto h-full">
    <div class="flex-1 overflow-y-auto py-4 space-y-6 px-6">
      <template v-for="message in messages" :key="message.id">
        <CopilotAgentMessage
          v-if="message.type === 'user'"
          :support-agent="supportAgent"
          :message="message"
        />
        <CopilotAssistantMessage
          v-else-if="['assistant', 'system'].includes(message.type)"
          :message="message"
        />
      </template>

      <CopilotLoader v-if="isCaptainTyping" />
    </div>

    <CopilotInput @send="sendMessage" />
  </div>
</template>
