<script setup>
import { nextTick, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';

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

const emit = defineEmits(['sendMessage', 'reset', 'setAssistant']);

const { t } = useI18n();

const COPILOT_USER_ROLES = ['assistant', 'system'];

const sendMessage = message => {
  emit('sendMessage', message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
};

const useSuggestion = opt => {
  emit('sendMessage', t(opt.prompt));
  useTrack(COPILOT_EVENTS.SEND_SUGGESTED);
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

const { updateUISettings } = useUISettings();

const closeCopilotPanel = () => {
  updateUISettings({
    is_copilot_panel_open: false,
    is_contact_sidebar_open: false,
  });
};

const handleSidebarAction = action => {
  if (action === 'reset') {
    emit('reset');
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
  <div class="flex flex-col h-full text-sm leading-6 tracking-tight w-full">
    <SidebarActionsHeader
      :title="$t('CAPTAIN.COPILOT.TITLE')"
      :buttons="[
        {
          key: 'reset',
          icon: 'i-lucide-refresh-ccw',
          tooltip: $t('CAPTAIN.COPILOT.RESET'),
        },
      ]"
      @click="handleSidebarAction"
      @close="closeCopilotPanel"
    />
    <div ref="chatContainer" class="flex-1 px-4 py-4 space-y-6 overflow-y-auto">
      <template v-for="message in messages" :key="message.id">
        <CopilotAgentMessage
          v-if="message.role === 'user'"
          :support-agent="supportAgent"
          :message="message"
        />
        <CopilotAssistantMessage
          v-else-if="COPILOT_USER_ROLES.includes(message.role)"
          :message="message"
          :conversation-inbox-type="conversationInboxType"
        />
      </template>

      <CopilotLoader v-if="isCaptainTyping" />
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
        <ToggleCopilotAssistant
          v-if="assistants.length"
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
