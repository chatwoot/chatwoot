<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotApprovalMessage from './CopilotApprovalMessage.vue';
import CopilotThinkingGroup from './CopilotThinkingGroup.vue';
import ToggleCopilotAssistant from './ToggleCopilotAssistant.vue';
import CopilotEmptyState from './CopilotEmptyState.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
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
  threads: {
    type: Array,
    default: () => [],
  },
  selectedThreadId: {
    type: Number,
    default: null,
  },
  hasMoreThreads: {
    type: Boolean,
    default: false,
  },
  isLoadingThreads: {
    type: Boolean,
    default: false,
  },
  isLoadingSelectedThread: {
    type: Boolean,
    default: false,
  },
  canSuggestReply: {
    type: Boolean,
    default: true,
  },
  canUseReply: {
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
  'loadMoreThreads',
]);

const { t } = useI18n();

const sendMessage = async message => {
  if (props.isLoadingSelectedThread) return false;

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

// An approval card waits on the agent, not on Copilot, so the loader stays hidden until they decide.
const isCopilotWorking = computed(() => {
  const hasApprovalAwaitingDecision = props.messages.some(
    message =>
      message.message_type === 'assistant_approval' &&
      message.message.approval.status === 'awaiting_approval'
  );
  return !isLastMessageFromAssistant.value && !hasApprovalAwaitingDecision;
});

const { updateUISettings } = useUISettings();

const closeCopilotPanel = () => {
  updateUISettings({
    is_copilot_panel_open: false,
    is_contact_sidebar_open: false,
  });
};

const showHistory = ref(false);
const handleSidebarAction = action => {
  if (action === 'new') {
    emit('reset');
    showHistory.value = false;
  } else if (action === 'history') {
    showHistory.value = !showHistory.value;
  }
};

const hasAssistants = computed(() => props.assistants.length > 0);
const hasMessages = computed(() => props.messages.length > 0);
const copilotButtons = computed(() => [
  {
    key: 'history',
    icon: 'i-lucide-history',
    tooltip: t('CAPTAIN.COPILOT.HISTORY'),
  },
  {
    key: 'new',
    icon: 'i-lucide-square-pen',
    tooltip: t('CAPTAIN.COPILOT.NEW_CHAT'),
  },
]);
const openThread = thread => {
  emit('selectThread', thread);
  showHistory.value = false;
};
watch(
  [() => props.messages],
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
      :buttons="copilotButtons"
      @click="handleSidebarAction"
      @close="closeCopilotPanel"
    />
    <div v-if="showHistory" class="flex-1 overflow-y-auto px-3 py-3">
      <div class="mb-3 flex items-center justify-between">
        <h3 class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.COPILOT.HISTORY') }}
        </h3>
        <button
          type="button"
          class="text-xs text-n-blue-11 hover:underline"
          @click="handleSidebarAction('new')"
        >
          {{ t('CAPTAIN.COPILOT.NEW_CHAT') }}
        </button>
      </div>
      <p
        v-if="isLoadingThreads && !threads.length"
        role="status"
        class="text-xs text-n-slate-11"
      >
        {{ t('CAPTAIN.COPILOT.LOADING_HISTORY') }}
      </p>
      <p v-else-if="!threads.length" class="text-xs text-n-slate-11">
        {{ t('CAPTAIN.COPILOT.NO_HISTORY') }}
      </p>
      <button
        v-for="thread in threads"
        :key="thread.id"
        type="button"
        class="mb-1 w-full rounded-lg px-3 py-2 text-left hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-11"
        :class="{ 'bg-n-alpha-2': thread.id === selectedThreadId }"
        @click="openThread(thread)"
      >
        <span class="block truncate text-sm text-n-slate-12">
          {{ thread.title }}
        </span>
      </button>
      <button
        v-if="hasMoreThreads"
        type="button"
        class="mt-2 w-full rounded-lg px-3 py-2 text-xs text-n-blue-11 hover:bg-n-alpha-2 disabled:cursor-wait disabled:opacity-60"
        :disabled="isLoadingThreads"
        @click="emit('loadMoreThreads')"
      >
        {{ t('CAPTAIN.COPILOT.LOAD_MORE') }}
      </button>
    </div>
    <div
      v-else
      ref="chatContainer"
      class="flex-1 flex px-4 py-4 overflow-y-auto items-start"
    >
      <p v-if="isLoadingSelectedThread" role="status" class="text-n-slate-11">
        {{ t('CAPTAIN.COPILOT.LOADING_CHAT') }}
      </p>
      <div
        v-else-if="hasMessages"
        class="space-y-6 flex-1 flex flex-col w-full"
      >
        <template v-for="(item, index) in groupedMessages" :key="item.id">
          <CopilotAgentMessage
            v-if="item.message_type === 'user'"
            :message="item.message"
          />
          <CopilotAssistantMessage
            v-else-if="item.message_type === 'assistant'"
            :message="item.message"
            :is-last-message="index === groupedMessages.length - 1"
            :can-use-reply="canUseReply"
          />
          <CopilotApprovalMessage
            v-else-if="item.message_type === 'assistant_approval'"
            :message="item.message"
          />
          <CopilotThinkingGroup
            v-else
            :messages="item.messages"
            :default-collapsed="isLastMessageFromAssistant"
          />
        </template>

        <CopilotLoader v-if="isCopilotWorking" />
      </div>
      <CopilotEmptyState
        v-else
        :has-assistants="hasAssistants"
        :can-suggest-reply="canSuggestReply"
        @use-suggestion="sendMessage"
      />
    </div>

    <div v-show="!showHistory" class="mx-3 mt-px mb-2">
      <div class="flex items-center gap-2 justify-between w-full mb-1">
        <ToggleCopilotAssistant
          v-if="assistants.length > 1 && !selectedThreadId"
          :assistants="assistants"
          :active-assistant="activeAssistant"
          @set-assistant="$event => emit('setAssistant', $event)"
        />
        <div v-else />
      </div>
      <CopilotInput
        v-if="hasAssistants"
        v-show="!isLoadingSelectedThread"
        class="mb-1 w-full"
        :on-send="sendMessage"
      />
    </div>
  </div>
</template>
