<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import wootConstants from 'dashboard/constants/globals';
import { MESSAGE_TYPE } from 'shared/constants/messages';

const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { isEnterprise } = useConfig();
const { width: windowWidth } = useWindowSize();

const currentUser = useMapGetter('getCurrentUser');
const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const inboxAssistant = useMapGetter('getCopilotAssistant');
const currentChat = useMapGetter('getSelectedChat');
const lastPublicMessage = useMapGetter('getLastEmailInSelectedChat');

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const selectedCopilotThreadId = ref(null);
const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](
    selectedCopilotThreadId.value
  )
);

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const isV2Enabled = computed(() =>
  isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.COPILOT_V2
  )
);
const selectedAssistantId = ref(null);
const selectedThread = ref(null);
const sessionVersion = ref(0);
const threadConversationId = ref(null);
const history = ref([]);
const historyNextPage = ref(null);
const historyLoading = ref(false);
const historyError = ref(false);
const messagesNextPage = ref(null);
const messagesLoading = ref(false);
const messagesError = ref(false);
let historyRequest = 0;
const sendingVersion = ref(null);

const activeAssistant = computed(() => {
  if (isV2Enabled.value) {
    if (selectedThread.value) return selectedThread.value.assistant;
    return (
      assistants.value.find(a => a.id === selectedAssistantId.value) || null
    );
  }
  const preferredId = uiSettings.value.preferred_captain_assistant_id;

  // If the user has selected a specific assistant, it takes first preference for Copilot.
  if (preferredId) {
    const preferredAssistant = assistants.value.find(a => a.id === preferredId);
    // Return the preferred assistant if found, otherwise continue to next cases
    if (preferredAssistant) return preferredAssistant;
  }

  // If the above is not available, the assistant connected to the inbox takes preference.
  if (inboxAssistant.value) {
    const inboxMatchedAssistant = assistants.value.find(
      a => a.id === inboxAssistant.value.id
    );
    if (inboxMatchedAssistant) return inboxMatchedAssistant;
  }
  // If neither of the above is available, the first assistant in the account takes preference.
  return assistants.value[0];
});

const canSuggestReply = computed(
  () =>
    Boolean(activeAssistant.value?.id) &&
    lastPublicMessage.value?.message_type === MESSAGE_TYPE.INCOMING
);

const closeCopilotPanel = () => {
  if (isSmallScreen.value && uiSettings.value?.is_copilot_panel_open) {
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: false,
    });
  }
};

const setAssistant = async assistant => {
  if (isV2Enabled.value) {
    if (!selectedThread.value)
      selectedAssistantId.value = assistant?.id || null;
    return;
  }
  selectedAssistantId.value = assistant.id;
  await updateUISettings({
    preferred_captain_assistant_id: assistant.id,
  });
};

const shouldShowCopilotPanel = computed(() => {
  if (!isEnterprise) {
    return false;
  }
  const isCaptainEnabled = isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
  const { is_copilot_panel_open: isCopilotPanelOpen } = uiSettings.value;
  return (
    (isCaptainEnabled || isV2Enabled.value) &&
    isCopilotPanelOpen &&
    (isV2Enabled.value || !uiFlags.value.fetchingList)
  );
});

const handleReset = () => {
  sessionVersion.value += 1;
  selectedCopilotThreadId.value = null;
  selectedThread.value = null;
  selectedAssistantId.value = null;
  threadConversationId.value = null;
  messagesNextPage.value = null;
  messagesLoading.value = false;
  messagesError.value = false;
};

const loadHistory = async (page = 1) => {
  historyRequest += 1;
  const request = historyRequest;
  const accountId = currentAccountId.value;
  historyLoading.value = true;
  historyError.value = false;
  try {
    const data = await store.dispatch('copilotThreads/getPage', { page });
    if (request !== historyRequest || accountId !== currentAccountId.value)
      return;
    const records = page === 1 ? [] : history.value;
    history.value = [...records, ...data.payload].filter(
      (thread, index, all) =>
        all.findIndex(item => item.id === thread.id) === index
    );
    historyNextPage.value = data.meta.next_page;
  } catch {
    if (request === historyRequest) historyError.value = true;
  } finally {
    if (request === historyRequest) historyLoading.value = false;
  }
};

const loadMessages = async (page = 1) => {
  if (!selectedCopilotThreadId.value || messagesLoading.value) return;
  const version = sessionVersion.value;
  messagesLoading.value = true;
  messagesError.value = false;
  try {
    const data = await store.dispatch('copilotMessages/getPage', {
      threadId: selectedCopilotThreadId.value,
      page,
    });
    if (version !== sessionVersion.value) return;
    messagesNextPage.value = data.meta.next_page;
  } catch {
    if (version === sessionVersion.value) messagesError.value = true;
  } finally {
    if (version === sessionVersion.value) messagesLoading.value = false;
  }
};

const selectThread = thread => {
  handleReset();
  selectedThread.value = thread;
  selectedCopilotThreadId.value = thread.id;
  loadMessages();
};

watch(() => currentChat.value?.id, handleReset);
watch(currentAccountId, () => {
  handleReset();
  historyRequest += 1;
  history.value = [];
  historyNextPage.value = null;
  historyLoading.value = false;
  historyError.value = false;
  if (isEnterprise) store.dispatch('captainAssistants/get');
});
watch(isV2Enabled, handleReset);
watch(
  [currentAccountId, isV2Enabled, shouldShowCopilotPanel],
  () => {
    if (isV2Enabled.value && shouldShowCopilotPanel.value) loadHistory();
  },
  { immediate: true }
);

const sendMessage = async payload => {
  const message = typeof payload === 'string' ? payload : payload.message;
  const requestType =
    typeof payload === 'string' ? undefined : payload.requestType;
  if (
    ((!isV2Enabled.value || requestType === 'reply_suggestion') &&
      !activeAssistant.value?.id) ||
    messagesLoading.value ||
    messagesError.value ||
    sendingVersion.value === sessionVersion.value
  )
    return false;
  const version = sessionVersion.value;
  const accountId = currentAccountId.value;
  const conversationId = currentChat.value?.id;
  sendingVersion.value = version;
  try {
    if (selectedCopilotThreadId.value) {
      await store.dispatch('copilotMessages/create', {
        assistant_id: activeAssistant.value?.id,
        conversation_id: isV2Enabled.value
          ? threadConversationId.value
          : conversationId,
        threadId: selectedCopilotThreadId.value,
        message,
      });
    } else {
      const response = await store.dispatch('copilotThreads/create', {
        assistant_id: activeAssistant.value?.id,
        conversation_id: conversationId,
        message,
        ...(requestType && { request_type: requestType }),
      });
      if (isV2Enabled.value && accountId === currentAccountId.value) {
        history.value = [response, ...history.value];
        // Refresh pagination and supersede any list request started before creation.
        loadHistory();
      }
      if (version === sessionVersion.value) {
        selectedCopilotThreadId.value = response.id;
        selectedThread.value = response;
        threadConversationId.value = conversationId;
        if (isV2Enabled.value) loadMessages();
      }
    }
    return true;
  } catch (error) {
    useAlert(error.message);
    return false;
  } finally {
    if (sendingVersion.value === version) sendingVersion.value = null;
  }
};

onMounted(() => {
  if (isEnterprise) {
    store.dispatch('captainAssistants/get');
  }
});
</script>

<template>
  <div
    v-if="shouldShowCopilotPanel"
    v-on-click-outside="() => closeCopilotPanel()"
    class="bg-n-surface-2 h-full overflow-hidden flex-col fixed top-0 ltr:right-0 rtl:left-0 z-40 w-full max-w-sm transition-transform duration-300 ease-in-out md:static md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
    :class="[
      {
        'md:flex': shouldShowCopilotPanel,
        'md:hidden': !shouldShowCopilotPanel,
      },
    ]"
  >
    <Copilot
      :messages="messages"
      :v2-enabled="isV2Enabled"
      :conversation-id="currentChat?.id"
      :session-key="sessionVersion"
      :selected-thread="selectedThread"
      :history="history"
      :history-loading="historyLoading"
      :history-error="historyError"
      :has-more-history="Boolean(historyNextPage)"
      :messages-loading="messagesLoading"
      :messages-error="messagesError"
      :has-older-messages="Boolean(messagesNextPage)"
      :support-agent="currentUser"
      :assistants="assistants"
      :active-assistant="activeAssistant"
      :can-suggest-reply="canSuggestReply"
      :on-send-message="sendMessage"
      @select-thread="selectThread"
      @load-history="loadHistory(historyNextPage || 1)"
      @retry-history="loadHistory()"
      @load-messages="loadMessages(messagesNextPage || 1)"
      @set-assistant="setAssistant"
      @reset="handleReset"
    />
  </div>
  <template v-else />
</template>
