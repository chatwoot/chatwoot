<script setup>
import {
  defineAsyncComponent,
  nextTick,
  ref,
  watch,
  computed,
  useTemplateRef,
} from 'vue';
import { useTimeoutFn } from '@vueuse/core';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useUISettings } from 'dashboard/composables/useUISettings';

import CopilotInput from './CopilotInput.vue';
import CopilotLoader from './CopilotLoader.vue';
import CopilotAgentMessage from './CopilotAgentMessage.vue';
import CopilotAssistantMessage from './CopilotAssistantMessage.vue';
import CopilotApprovalMessage from './CopilotApprovalMessage.vue';
import CopilotReviewProgress from './CopilotReviewProgress.vue';
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
  isExpanded: {
    type: Boolean,
    default: false,
  },
  canShowAvatar: {
    type: Boolean,
    default: false,
  },
  onSendMessage: {
    type: Function,
    required: true,
  },
  // The old Copilot answers each message on its own and cannot be stopped.
  canStop: {
    type: Boolean,
    default: false,
  },
  onStop: {
    type: Function,
    default: () => {},
  },
});

const emit = defineEmits([
  'reset',
  'setAssistant',
  'selectThread',
  'loadMoreThreads',
  'toggleExpand',
]);

const { t } = useI18n();

const EMPTY_STATE_AVATAR_SIZE = 96;
// Below 64px the avatar drops to low detail, so the dock stays at 64px.
const DOCK_AVATAR_SIZE = 64;
const HAPPY_DURATION = 1000;
// Long enough for one full head shake.
const ERROR_DURATION = 2400;
const SLEEP_AFTER = 2 * 60 * 1000;
const SEARCH_STEP_PREFIXES = ['search_', 'get_'];

// The avatar needs WebGL2 on real graphics hardware. Checking first avoids downloading it where it can't render.
const supportsCaptainAvatar = () => {
  try {
    const gl = document.createElement('canvas').getContext('webgl2', {
      failIfMajorPerformanceCaveat: true,
    });
    gl?.getExtension('WEBGL_lose_context')?.loseContext();
    return !!gl;
  } catch {
    return false;
  }
};

const CopilotAvatar = defineAsyncComponent(() => import('./CopilotAvatar.vue'));
// The avatar emits unsupported when its graphics context is lost for good, so the logo comes back.
const isAvatarSupported = ref(supportsCaptainAvatar());
const showAvatar = computed(
  () => props.canShowAvatar && isAvatarSupported.value
);

const draft = ref('');
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

// Stopping marks the agent's message instead of answering it.
const isLastRequestStopped = computed(() => {
  const lastRequest = props.messages.findLast(
    message => message.message_type === 'user'
  );
  return lastRequest?.message.status === 'stopped';
});

// An approval card waits on the agent, not on Copilot, so the loader stays hidden until they decide.
const isCopilotWorking = computed(() => {
  const hasApprovalAwaitingDecision = props.messages.some(
    message =>
      message.message_type === 'assistant_approval' &&
      message.message.approval.status === 'awaiting_approval'
  );
  return (
    !isLastMessageFromAssistant.value &&
    !hasApprovalAwaitingDecision &&
    !isLastRequestStopped.value
  );
});

// Only workflow steps save a run ID, so the old Copilot's steps keep the loader.
const hasLiveStep = (item, index) =>
  isCopilotWorking.value &&
  index === groupedMessages.value.length - 1 &&
  Boolean(item.messages.at(-1).message.run_id);

// Copilot answers one message at a time, so while it works the agent can stop it but not send another message. A new
// chat has no messages, so there is nothing to stop.
const isStoppable = computed(
  () => props.canStop && props.messages.length > 0 && isCopilotWorking.value
);

const showLoader = computed(() => {
  if (!isCopilotWorking.value) return false;
  const index = groupedMessages.value.length - 1;
  const item = groupedMessages.value[index];
  if (item.message_type === 'thinking_group') return !hasLiveStep(item, index);
  if (item.message_type === 'assistant_progress') {
    return item.message.progress.finished;
  }
  const { approval } = item.message;
  if (approval?.status === 'approved') {
    return Boolean(approval.progress?.finished);
  }
  return true;
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
  } else if (action === 'expand') {
    emit('toggleExpand');
  }
  // A click on a header button leaves the text selection where it was, often in the reply box, so a paste would land
  // there unless the input takes focus back.
  if (!showHistory.value) focusInput();
};

const hasAssistants = computed(() => props.assistants.length > 0);
const hasMessages = computed(() => props.messages.length > 0);

const liveStep = computed(() => {
  if (!hasMessages.value) return null;
  const index = groupedMessages.value.length - 1;
  const item = groupedMessages.value[index];
  if (item.message_type !== 'thinking_group' || !hasLiveStep(item, index)) {
    return null;
  }
  return item.messages.at(-1).message;
});

// What Copilot is doing in the current turn, or null when the turn is over or waits on the agent.
const turnAvatarState = computed(() => {
  if (!hasMessages.value || !isCopilotWorking.value) return null;
  const step = liveStep.value;
  if (step) {
    if (step.status === 'failed') return 'error';
    const isSearch = SEARCH_STEP_PREFIXES.some(prefix =>
      step.function_name.startsWith(prefix)
    );
    return isSearch ? 'searching' : 'working';
  }
  // Without a live step, the loader shows while Copilot thinks. Otherwise a review or an approved action is running.
  return showLoader.value ? 'thinking' : 'working';
});

const reaction = ref(null);
const { start: startReaction } = useTimeoutFn(
  () => {
    reaction.value = null;
  },
  () => (reaction.value === 'error' ? ERROR_DURATION : HAPPY_DURATION),
  { immediate: false }
);
// A turn that ends with a reply shows the happy face for a moment, and one that ends with a failed reply shows the
// error face. Opening a past chat shows neither, because no turn was running.
watch(turnAvatarState, (state, previousState) => {
  if (previousState && !state && isLastMessageFromAssistant.value) {
    const hasFailed = props.messages.at(-1).message.status === 'failed';
    reaction.value = hasFailed ? 'error' : 'happy';
    startReaction();
  }
});

const awakeAvatarState = computed(() => {
  if (turnAvatarState.value) return turnAvatarState.value;
  if (reaction.value) return reaction.value;
  return draft.value.trim() ? 'typing' : 'idle';
});

// Captain falls asleep after a while in idle. Any other state, focusing the input or clicking the avatar wakes it.
const isSleeping = ref(false);
const { start: startSleepTimer, stop: stopSleepTimer } = useTimeoutFn(
  () => {
    isSleeping.value = true;
  },
  SLEEP_AFTER,
  { immediate: false }
);
const wakeAvatar = () => {
  isSleeping.value = false;
  if (awakeAvatarState.value === 'idle') startSleepTimer();
  else stopSleepTimer();
};
watch(awakeAvatarState, wakeAvatar, { immediate: true });

const avatarState = computed(() =>
  isSleeping.value ? 'sleeping' : awakeAvatarState.value
);

// The dock takes over from the loader and the live step row, so it repeats their text.
const avatarStatus = computed(() => {
  if (liveStep.value) return liveStep.value.content;
  if (avatarState.value === 'thinking') return t('CAPTAIN.COPILOT.LOADER');
  return '';
});
const showAvatarDock = computed(() => showAvatar.value && hasMessages.value);

// Full screen opens with Captain putting on the headset. The empty state avatar plays it when it mounts in full screen,
// and switching to full screen replays it on whichever avatar is on screen.
const emptyStateAvatar = useTemplateRef('emptyStateAvatar');
const dockAvatar = useTemplateRef('dockAvatar');
// Neither avatar is on screen without the flag, without WebGL2, or before the chunk loads.
const shownAvatar = () => emptyStateAvatar.value ?? dockAvatar.value;
watch(
  () => props.isExpanded,
  isExpanded => {
    if (isExpanded) shownAvatar()?.enter();
  },
  { flush: 'post' }
);
// The typing face reads along with each keystroke.
const onDraftInput = () => shownAvatar()?.keyStroke();
// The panel already fills the screen below md, so the toggle only shows on wider screens.
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
  {
    key: 'expand',
    icon: props.isExpanded ? 'i-lucide-minimize-2' : 'i-lucide-maximize-2',
    tooltip: props.isExpanded
      ? t('CAPTAIN.COPILOT.SHRINK')
      : t('CAPTAIN.COPILOT.EXPAND'),
    class: 'hidden md:inline-flex',
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
      <div class="w-full max-w-3xl mx-auto">
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
    </div>
    <div
      v-else
      ref="chatContainer"
      class="flex-1 flex px-4 py-4 overflow-y-auto no-scrollbar items-start"
    >
      <p
        v-if="isLoadingSelectedThread"
        role="status"
        class="w-full max-w-3xl mx-auto text-n-slate-11"
      >
        {{ t('CAPTAIN.COPILOT.LOADING_CHAT') }}
      </p>
      <div
        v-else-if="hasMessages"
        class="space-y-6 flex-1 flex flex-col w-full max-w-3xl mx-auto"
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
          <CopilotReviewProgress
            v-else-if="item.message_type === 'assistant_progress'"
            :progress="item.message.progress"
          />
          <CopilotThinkingGroup
            v-else
            :messages="item.messages"
            :is-active="hasLiveStep(item, index) && !showAvatarDock"
          />
        </template>

        <CopilotLoader v-if="showLoader && !showAvatarDock" />
      </div>
      <CopilotEmptyState
        v-else
        class="max-w-3xl mx-auto"
        :has-assistants="hasAssistants"
        :can-suggest-reply="canSuggestReply"
        @use-suggestion="sendSuggestion"
      >
        <template v-if="showAvatar" #logo>
          <CopilotAvatar
            ref="emptyStateAvatar"
            :state="avatarState"
            :size="EMPTY_STATE_AVATAR_SIZE"
            :entrance="isExpanded"
            :label="t('CAPTAIN.COPILOT.AVATAR_LABEL')"
            @unsupported="isAvatarSupported = false"
            @poke="wakeAvatar"
          />
        </template>
      </CopilotEmptyState>
    </div>

    <div v-show="!showHistory" class="mx-4 mt-px mb-2">
      <div
        v-if="showAvatarDock"
        class="flex items-center gap-3 w-full max-w-3xl mx-auto mb-2 px-1"
      >
        <CopilotAvatar
          ref="dockAvatar"
          :state="avatarState"
          :size="DOCK_AVATAR_SIZE"
          :label="t('CAPTAIN.COPILOT.AVATAR_LABEL')"
          @unsupported="isAvatarSupported = false"
          @poke="wakeAvatar"
        />
        <span role="status" class="min-w-0 truncate text-sm text-n-slate-11">
          {{ avatarStatus }}
        </span>
      </div>
      <div
        class="flex items-center gap-2 justify-between w-full max-w-3xl mx-auto mb-1"
      >
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
        v-model="draft"
        class="mb-1 w-full max-w-3xl mx-auto"
        :on-send="sendMessage"
        :is-working="isStoppable"
        :on-stop="onStop"
        @focusin="wakeAvatar"
        @input="onDraftInput"
      />
    </div>
  </div>
</template>
