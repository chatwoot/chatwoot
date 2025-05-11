<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import Icon from '../icon/Icon.vue';
import Button from '../button/Button.vue';

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

const { t } = useI18n();

const sendMessage = message => {
  emit('sendMessage', message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
};

const useSuggestion = opt => {
  emit('sendMessage', t(opt.prompt));
  useTrack(COPILOT_EVENTS.SEND_SUGGESTED);
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

const promptOptions = [
  {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL',
    prompt: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
  },
  {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL',
    prompt: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
  },
  {
    label: 'CAPTAIN.COPILOT.PROMPTS.RATE.LABEL',
    prompt: 'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT',
  },
];

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
    <div
      class="flex items-center justify-between px-4 py-2 border-b border-n-weak h-12"
    >
      <div class="flex items-center justify-between gap-2 flex-1">
        <span class="font-medium text-sm text-n-slate-12">
          {{ $t('CAPTAIN.COPILOT.TITLE') }}
        </span>
        <div class="flex items-center">
          <Button
            v-if="messages.length"
            icon="i-lucide-plus"
            ghost
            sm
            @click="handleReset"
          />
          <Button icon="i-lucide-x" ghost sm @click="$emit('close')" />
        </div>
      </div>
    </div>
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
      <div
        v-if="!messages.length"
        class="flex-1 flex items-center justify-center"
      >
        <div class="h-fit px-3 py-3 space-y-1">
          <span class="text-xs text-n-slate-10">
            {{ $t('COPILOT.TRY_THESE_PROMPTS') }}
          </span>
          <button
            v-for="prompt in promptOptions"
            :key="prompt.label"
            class="px-2 py-1 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11 flex items-center gap-1"
            @click="() => useSuggestion(prompt)"
          >
            <span>{{ t(prompt.label) }}</span>
            <Icon icon="i-lucide-chevron-right" />
          </button>
        </div>
      </div>
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
