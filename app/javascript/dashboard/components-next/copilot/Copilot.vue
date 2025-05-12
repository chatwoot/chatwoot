<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import CopilotHeader from './CopilotHeader.vue';
import CopilotEmptyState from './CopilotEmptyState.vue';

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
  conversationInboxType: {
    type: String,
    required: true,
  },
  assistants: {
    type: Array,
    default: () => [],
  },
  activeAssistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'reset', 'setAssistant', 'close']);

const sendMessage = message => {
  emit('sendMessage', message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
};

const handleReset = () => {
  emit('reset');
};

const chatContainer = ref(null);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const groupedMessages = computed(() => {
  const result = [];
  let thinkingGroup = [];

  props.messages.forEach(message => {
    if (message.role === 'assistant_thinking') {
      thinkingGroup.push(message);
    } else {
      if (thinkingGroup.length > 0) {
        result.push({ type: 'thinking_group', messages: thinkingGroup });
        thinkingGroup = [];
      }
      result.push({ type: 'message', message });
    }
  });

  if (thinkingGroup.length > 0) {
    result.push({ type: 'thinking_group', messages: thinkingGroup });
  }

  return result;
});

watch(
  [() => props.messages, () => props.isCaptainTyping],
  () => {
    scrollToBottom();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col h-full text-sm leading-6 tracking-tight w-full">
    <CopilotHeader
      :has-messages="messages.length > 0"
      @reset="handleReset"
      @close="$emit('close')"
    />
    <div
      ref="chatContainer"
      class="flex-1 flex px-4 py-4 overflow-y-auto items-start"
    >
      <div v-if="messages.length" class="space-y-6 flex-1 flex flex-col">
        <template
          v-for="item in groupedMessages"
          :key="item.type === 'message' ? item.message.id : 'thinking-group'"
        >
          <template v-if="item.type === 'message'">
            <CopilotAgentMessage
              v-if="item.message.role === 'user'"
              :support-agent="supportAgent"
              :message="item.message"
            />
            <CopilotAssistantMessage
              v-else-if="
                item.message.role === 'assistant' ||
                item.message.role === 'system'
              "
              :message="item.message"
              :conversation-inbox-type="conversationInboxType"
            />
          </template>
          <CopilotThinkingGroup
            v-else
            :messages="item.messages"
            :has-assistant-message-after="
              groupedMessages[groupedMessages.indexOf(item) + 1]?.message
                ?.role === 'assistant'
            "
          />
        </template>

        <CopilotLoader v-if="isCaptainTyping" />
      </div>
      <CopilotEmptyState
        v-if="!messages.length"
        @use-suggestion="sendMessage"
      />
    </div>

    <div class="mx-3 mt-px mb-2">
      <div class="flex items-center gap-2 justify-between w-full mb-1">
        <ToggleCopilotAssistant
          v-if="assistants.length > 1"
          :assistants="assistants"
          :active-assistant="activeAssistant"
          @set-assistant="$event => emit('setAssistant', $event)"
        />
        <div v-else />
      </div>
      <CopilotInput class="mb-1 w-full" @send="sendMessage" />
    </div>
  </div>
</template>
