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
import CopilotEmptyState from './CopilotEmptyState.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import Icon from '../icon/Icon.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  messages: {
    type: Array,
    default: () => [],
  },
  activeAssistant: {
    type: Object,
    default: null,
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
  canSuggestReply: {
    type: Boolean,
    default: true,
  },
  onSendMessage: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['reset', 'selectThread', 'loadMoreThreads']);

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
  } else if (action === 'history') {
    showHistory.value = !showHistory.value;
  }
};

const sourceLabel = computed(() => props.activeAssistant?.name);
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
          class="text-xs text-n-blue-11 hover:underline"
          @click="handleSidebarAction('new')"
        >
          {{ t('CAPTAIN.COPILOT.NEW_CHAT') }}
        </button>
      </div>
      <p
        v-if="!threads.length && !isLoadingThreads"
        class="text-xs text-n-slate-11"
      >
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
        <span class="block truncate text-sm text-n-slate-12">{{
          thread.title
        }}</span>
        <span
          v-if="thread.assistant"
          class="block truncate text-xs text-n-slate-10"
          >{{ thread.assistant.name }}</span
        >
      </button>
      <button
        v-if="hasMoreThreads"
        type="button"
        class="mt-2 w-full rounded-lg px-3 py-2 text-xs text-n-blue-11 hover:bg-n-alpha-2"
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
        v-else
        :can-suggest-reply="canSuggestReply"
        :has-assistant="Boolean(activeAssistant)"
        @use-suggestion="sendMessage"
      />
    </div>

    <div v-if="!showHistory" class="mx-3 mt-px mb-2">
      <div
        v-if="activeAssistant"
        class="mb-2 flex items-center gap-1.5 px-1 text-xs text-n-slate-10"
        :title="sourceLabel"
      >
        <Icon icon="i-lucide-sparkles" class="shrink-0 text-sm" />
        <span class="truncate">{{ sourceLabel }}</span>
      </div>
      <CopilotInput
        v-if="activeAssistant"
        class="mb-1 w-full"
        :on-send="sendMessage"
      />
    </div>
  </div>
</template>
