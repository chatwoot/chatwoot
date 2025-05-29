<script setup>
import { nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotTopicMessage from './CopilotTopicMessage.vue';
import ToggleCopilotTopic from './ToggleCopilotTopic.vue';
import Icon from '../icon/Icon.vue';

const props = defineProps({
  supportAgent: {
    type: Object,
    default: () => ({}),
  },
  messages: {
    type: Array,
    default: () => [],
  },
  isAiagentTyping: {
    type: Boolean,
    default: false,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
  topics: {
    type: Array,
    default: () => [],
  },
  activeTopic: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['sendMessage', 'reset', 'setTopic']);

const { t } = useI18n();

const COPILOT_USER_ROLES = ['topic', 'system'];

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

const promptOptions = [
  {
    label: 'AIAGENT.COPILOT.PROMPTS.SUMMARIZE.LABEL',
    prompt: 'AIAGENT.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
  },
  {
    label: 'AIAGENT.COPILOT.PROMPTS.SUGGEST.LABEL',
    prompt: 'AIAGENT.COPILOT.PROMPTS.SUGGEST.CONTENT',
  },
  {
    label: 'AIAGENT.COPILOT.PROMPTS.RATE.LABEL',
    prompt: 'AIAGENT.COPILOT.PROMPTS.RATE.CONTENT',
  },
];

watch(
  [() => props.messages, () => props.isAiagentTyping],
  () => {
    scrollToBottom();
  },
  { deep: true }
);
</script>

<template>
  <div class="flex flex-col h-full text-sm leading-6 tracking-tight w-full">
    <div ref="chatContainer" class="flex-1 px-4 py-4 space-y-6 overflow-y-auto">
      <template v-for="message in messages" :key="message.id">
        <CopilotAgentMessage
          v-if="message.role === 'user'"
          :support-agent="supportAgent"
          :message="message"
        />
        <CopilotTopicMessage
          v-else-if="COPILOT_USER_ROLES.includes(message.role)"
          :message="message"
          :conversation-inbox-type="conversationInboxType"
        />
      </template>

      <CopilotLoader v-if="isAiagentTyping" />
    </div>

    <div
      v-if="!messages.length"
      class="h-full w-full flex items-center justify-center"
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

    <div class="mx-3 mt-px mb-2">
      <div class="flex items-center gap-2 justify-between w-full mb-1">
        <ToggleCopilotTopic
          v-if="topics.length"
          :topics="topics"
          :active-topic="activeTopic"
          @set-topic="$event => emit('setTopic', $event)"
        />
        <div v-else />
        <button
          v-if="messages.length"
          class="text-xs flex items-center gap-1 hover:underline"
          @click="handleReset"
        >
          <i class="i-lucide-refresh-ccw" />
          <span>{{ $t('AIAGENT.COPILOT.RESET') }}</span>
        </button>
      </div>
      <CopilotInput class="mb-1 w-full" @send="sendMessage" />
    </div>
  </div>
</template>
