<script setup>
import { nextTick, ref, watch, computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
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

const chatContainer = ref(null);
const copilotInput = ref(null);
// A paste only lands in a focused field, so actions that move focus off the input hand it back.
const focusInput = () => nextTick(() => copilotInput.value?.focus());
// Within this distance of the end, the agent is following the chat and new messages keep it in view.
const FOLLOW_DISTANCE_PX = 80;

const scrollToBottom = async () => {
  await nextTick();
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const isFollowingChat = () => {
  const container = chatContainer.value;
  if (!container) return true;

  const { scrollHeight, scrollTop, clientHeight } = container;
  return scrollHeight - scrollTop - clientHeight <= FOLLOW_DISTANCE_PX;
};

const sendMessage = async message => {
  if (props.isLoadingSelectedThread) return false;

  const isSuccess = await props.onSendMessage(message);
  useTrack(COPILOT_EVENTS.SEND_MESSAGE);
  if (isSuccess) scrollToBottom();
  return isSuccess;
};

const sendSuggestion = suggestion => {
  focusInput();
  return sendMessage(suggestion);
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
    focusInput();
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
// The store refreshes the message list for every thread's update, so only a new last message in this chat counts.
// Watchers run before the DOM updates, so the position checked is the one the agent was reading.
watch(
  () => props.messages[props.messages.length - 1]?.id,
  () => {
    if (isFollowingChat()) scrollToBottom();
  }
);

// An opened chat starts at its latest message.
watch(
  () => [props.selectedThreadId, props.isLoadingSelectedThread],
  ([threadId, isLoading], [, wasLoading]) => {
    if (isLoading) return;
    scrollToBottom();
    // The input is hidden while a chat loads, which drops focus.
    if (wasLoading && threadId) focusInput();
  }
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
        class="mb-1 w-full rounded-lg px-3 py-2 text-start hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-blue-11"
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
        v-else
        :has-assistants="hasAssistants"
        :can-suggest-reply="canSuggestReply"
        @use-suggestion="sendSuggestion"
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
        ref="copilotInput"
        class="mb-1 w-full"
        :on-send="sendMessage"
      />
    </div>
  </div>
</template>
