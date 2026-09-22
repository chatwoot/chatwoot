<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotHistory from './CopilotHistory.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import CopilotEmptyState from './CopilotEmptyState.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  v2Enabled: { type: Boolean, default: false },
  conversationId: { type: [Number, String], default: null },
  sessionKey: { type: Number, default: 0 },
  selectedThread: { type: Object, default: null },
  history: { type: Array, default: () => [] },
  historyLoading: { type: Boolean, default: false },
  historyError: { type: Boolean, default: false },
  hasMoreHistory: { type: Boolean, default: false },
  messagesLoading: { type: Boolean, default: false },
  messagesError: { type: Boolean, default: false },
  hasOlderMessages: { type: Boolean, default: false },
  messages: {
    type: Array,
    default: () => [],
  },
  assistants: {
    type: Array,
    default: () => [],
  },
  activeAssistant: {
    type: Object,
    default: () => ({}),
  },
  canSuggestReply: {
    type: Boolean,
    default: true,
  },
  onSendMessage: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits([
  'reset',
  'setAssistant',
  'selectThread',
  'loadHistory',
  'retryHistory',
  'loadMessages',
]);
const showHistory = ref(false);
const newChat = () => {
  showHistory.value = false;
  emit('reset');
};
const selectThread = thread => {
  showHistory.value = false;
  emit('selectThread', thread);
};
watch(
  () => props.sessionKey,
  () => {
    showHistory.value = false;
  }
);
const isUnavailable = computed(
  () => props.selectedThread?.execution_availability?.available === false
);

const { t } = useI18n();

const sendMessage = async message => {
  const isSuccess = await props.onSendMessage(message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
  return isSuccess;
};

const chatContainer = ref(null);

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

watch(showHistory, visible => {
  if (!visible) scrollToBottom();
});

const groupedMessages = computed(() => {
  const result = [];
  let thinkingGroup = [];
  props.messages.forEach(message => {
    if (message.message_type === 'assistant_thinking') {
      thinkingGroup.push(message);
    } else {
      if (thinkingGroup.length > 0) {
        result.push({
          id: thinkingGroup[0].id,
          message_type: 'thinking_group',
          messages: thinkingGroup,
        });
        thinkingGroup = [];
      }
      result.push(message);
    }
  });
  if (thinkingGroup.length > 0) {
    result.push({
      id: thinkingGroup[0].id,
      message_type: 'thinking_group',
      messages: thinkingGroup,
    });
  }
  return result;
});

const isLastMessageFromAssistant = computed(() => {
  return (
    groupedMessages.value[groupedMessages.value.length - 1]?.message_type ===
    'assistant'
  );
});

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

const hasAssistants = computed(() => props.assistants.length > 0);
const hasMessages = computed(() => props.messages.length > 0);
const copilotButtons = computed(() => {
  if (hasMessages.value && !props.v2Enabled) {
    return [
      {
        key: 'reset',
        icon: 'i-lucide-refresh-ccw',
        tooltip: t('CAPTAIN.COPILOT.RESET'),
      },
    ];
  }
  return [];
});
watch(
  () => props.messages.at(-1),
  () => scrollToBottom(),
  { deep: true }
);
const loadOlderMessages = async () => {
  const container = chatContainer.value;
  const height = container?.scrollHeight || 0;
  const scrollTop = container?.scrollTop || 0;
  emit('loadMessages');
  // Preserve the reading position when an older page is prepended.
  const stop = watch(
    () => props.messagesLoading,
    async loading => {
      if (loading) return;
      await nextTick();
      if (container && container === chatContainer.value) {
        container.scrollTop = scrollTop + container.scrollHeight - height;
      }
      stop();
    }
  );
};
</script>

<template>
  <div class="flex flex-col h-full text-sm leading-6 tracking-tight w-full">
    <SidebarActionsHeader
      :title="$t('CAPTAIN.COPILOT.TITLE')"
      :buttons="copilotButtons"
      @click="handleSidebarAction"
      @close="closeCopilotPanel"
    />
    <div
      v-if="v2Enabled"
      class="flex items-center gap-2 px-3 pb-3 border-b border-n-weak"
    >
      <Button
        :label="$t('CAPTAIN.COPILOT.NEW_CHAT')"
        icon="i-lucide-plus"
        sm
        slate
        outline
        @click="newChat"
      />
      <Button
        :label="$t('CAPTAIN.COPILOT.HISTORY')"
        icon="i-lucide-history"
        :aria-expanded="showHistory"
        sm
        slate
        ghost
        @click="showHistory = !showHistory"
      />
    </div>
    <CopilotHistory
      v-if="v2Enabled && showHistory"
      :threads="history"
      :selected-id="selectedThread?.id"
      :loading="historyLoading"
      :error="historyError"
      :has-more="hasMoreHistory"
      @select="selectThread"
      @load-more="emit('loadHistory')"
      @retry="emit('retryHistory')"
    />
    <div
      v-else
      ref="chatContainer"
      class="flex-1 min-h-0 flex flex-col px-4 py-4 overflow-y-auto items-start"
    >
      <div
        v-if="messagesLoading"
        role="status"
        class="w-full pb-3 text-n-slate-11"
      >
        {{ $t('CAPTAIN.COPILOT.MESSAGES_LOADING') }}
      </div>
      <div v-else-if="messagesError" role="alert" class="w-full pb-3 space-y-2">
        <p class="text-n-slate-11">
          {{ $t('CAPTAIN.COPILOT.MESSAGES_ERROR') }}
        </p>
        <Button
          :label="$t('CAPTAIN.COPILOT.RETRY')"
          sm
          slate
          outline
          @click="emit('loadMessages')"
        />
      </div>
      <Button
        v-else-if="hasOlderMessages"
        :label="$t('CAPTAIN.COPILOT.LOAD_OLDER')"
        class="mb-4 mx-auto"
        sm
        slate
        ghost
        @click="loadOlderMessages"
      />
      <div v-if="hasMessages" class="space-y-6 flex-1 flex flex-col w-full">
        <template v-for="(item, index) in groupedMessages" :key="item.id">
          <CopilotAgentMessage
            v-if="item.message_type === 'user'"
            :message="item.message"
          />
          <CopilotAssistantMessage
            v-else-if="item.message_type === 'assistant'"
            :message="item.message"
            :is-last-message="index === groupedMessages.length - 1"
          />
          <CopilotThinkingGroup
            v-else
            :messages="item.messages"
            :default-collapsed="isLastMessageFromAssistant"
          />
        </template>

        <CopilotLoader v-if="!isLastMessageFromAssistant" />
      </div>
      <CopilotEmptyState
        v-else-if="!messagesLoading && !messagesError"
        :has-assistants="hasAssistants || v2Enabled"
        :v2-enabled="v2Enabled"
        :conversation-id="conversationId"
        :can-suggest-reply="canSuggestReply"
        @use-suggestion="sendMessage"
      />
    </div>

    <div v-show="!showHistory" class="mx-3 mt-px mb-2">
      <p
        v-if="isUnavailable"
        role="status"
        class="text-xs text-n-slate-11 mb-2"
      >
        {{ $t('CAPTAIN.COPILOT.EXECUTION_UNAVAILABLE') }}
      </p>
      <div class="flex items-center gap-2 justify-between w-full mb-1">
        <ToggleCopilotAssistant
          v-if="
            (v2Enabled && !selectedThread) ||
            (!v2Enabled && assistants.length > 1)
          "
          :assistants="assistants"
          :allow-none="v2Enabled"
          :active-assistant="activeAssistant"
          @set-assistant="$event => emit('setAssistant', $event)"
        />
        <p
          v-else-if="v2Enabled && selectedThread"
          class="text-xs text-n-slate-11 truncate"
        >
          {{ activeAssistant?.name || $t('CAPTAIN.COPILOT.NO_ASSISTANT') }}
        </p>
        <div v-else />
      </div>
      <CopilotInput
        v-if="hasAssistants || v2Enabled"
        :key="sessionKey"
        :disabled="messagesLoading || messagesError || isUnavailable"
        class="mb-1 w-full"
        :on-send="sendMessage"
      />
    </div>
  </div>
</template>
