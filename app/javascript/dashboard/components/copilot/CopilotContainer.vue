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
import CopilotThreadsAPI from 'dashboard/api/captain/copilotThreads';

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

const canSuggestReply = computed(
  () => lastPublicMessage.value?.message_type === MESSAGE_TYPE.INCOMING
);

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const selectedCopilotThreadId = ref(null);
const isLoadingSelectedThread = ref(false);
const threads = ref([]);
const historyPage = ref(0);
const hasMoreThreads = ref(false);
const isLoadingThreads = ref(false);
let accountVersion = 0;
let selectionVersion = 0;
const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](
    selectedCopilotThreadId.value
  )
);

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const isCopilotAvailable = computed(
  () =>
    isEnterprise &&
    isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CAPTAIN
    )
);

const selectedAssistantId = ref(null);
const selectedThread = computed(() =>
  threads.value.find(thread => thread.id === selectedCopilotThreadId.value)
);

const activeAssistant = computed(() => {
  if (selectedThread.value?.assistant) return selectedThread.value.assistant;

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

const closeCopilotPanel = () => {
  if (isSmallScreen.value && uiSettings.value?.is_copilot_panel_open) {
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: false,
    });
  }
};

const setAssistant = async assistant => {
  selectedAssistantId.value = assistant.id;
  await updateUISettings({
    preferred_captain_assistant_id: assistant.id,
  });
};

const shouldShowCopilotPanel = computed(() => {
  const { is_copilot_panel_open: isCopilotPanelOpen } = uiSettings.value;
  return (
    isCopilotAvailable.value &&
    isCopilotPanelOpen &&
    !uiFlags.value.fetchingList
  );
});

const handleReset = () => {
  selectionVersion += 1;
  selectedCopilotThreadId.value = null;
  isLoadingSelectedThread.value = false;
};

watch(() => currentChat.value?.id, handleReset);

const loadThreads = async (page = 1) => {
  const version = accountVersion;
  const accountId = currentAccountId.value;
  const threadIdsAtRequestStart = new Set(
    threads.value.map(thread => thread.id)
  );
  isLoadingThreads.value = true;

  try {
    const { data } = await CopilotThreadsAPI.get({ page });
    if (
      version !== accountVersion ||
      Number(accountId) !== Number(currentAccountId.value)
    ) {
      return;
    }

    const responseIds = new Set(data.payload.map(thread => thread.id));
    if (page === 1) {
      const threadsCreatedWhileLoading = threads.value.filter(
        thread =>
          !threadIdsAtRequestStart.has(thread.id) && !responseIds.has(thread.id)
      );
      threads.value = [...threadsCreatedWhileLoading, ...data.payload];
    } else {
      const knownIds = new Set(threads.value.map(thread => thread.id));
      threads.value = [
        ...threads.value,
        ...data.payload.filter(thread => !knownIds.has(thread.id)),
      ];
    }
    historyPage.value = page;
    hasMoreThreads.value = threads.value.length < data.meta.total_count;
  } catch (error) {
    if (version === accountVersion) useAlert(error.message);
  } finally {
    if (version === accountVersion) isLoadingThreads.value = false;
  }
};

const selectThread = async thread => {
  selectionVersion += 1;
  const version = selectionVersion;
  const currentVersion = accountVersion;
  const previousThreadId = selectedCopilotThreadId.value;
  selectedCopilotThreadId.value = thread.id;
  isLoadingSelectedThread.value = true;

  try {
    await store.dispatch('copilotMessages/fetchThread', {
      threadId: thread.id,
    });
  } catch (error) {
    if (selectionVersion === version && accountVersion === currentVersion) {
      selectedCopilotThreadId.value = previousThreadId;
      useAlert(error.message);
    }
  } finally {
    if (selectionVersion === version && accountVersion === currentVersion) {
      isLoadingSelectedThread.value = false;
    }
  }
};

watch(
  [currentAccountId, isCopilotAvailable],
  ([, isAvailable]) => {
    accountVersion += 1;
    selectionVersion += 1;
    selectedCopilotThreadId.value = null;
    isLoadingSelectedThread.value = false;
    threads.value = [];
    historyPage.value = 0;
    hasMoreThreads.value = false;
    isLoadingThreads.value = false;
    if (isAvailable) loadThreads();
  },
  { immediate: true }
);

const sendMessage = async payload => {
  if (isLoadingSelectedThread.value) return false;

  const message = typeof payload === 'string' ? payload : payload.message;
  const requestType =
    typeof payload === 'string' ? undefined : payload.requestType;

  try {
    if (selectedCopilotThreadId.value) {
      await store.dispatch('copilotMessages/create', {
        assistant_id: activeAssistant.value.id,
        conversation_id: currentChat.value?.id,
        threadId: selectedCopilotThreadId.value,
        message,
      });
    } else {
      const currentVersion = accountVersion;
      const accountId = currentAccountId.value;
      const conversationId = currentChat.value?.id;
      const response = await store.dispatch('copilotThreads/create', {
        assistant_id: activeAssistant.value.id,
        conversation_id: conversationId,
        message,
        ...(requestType && { request_type: requestType }),
      });
      if (
        currentVersion !== accountVersion ||
        Number(accountId) !== Number(currentAccountId.value)
      ) {
        return true;
      }
      if (currentChat.value?.id === conversationId) {
        selectedCopilotThreadId.value = response.id;
      }
      if (!threads.value.some(thread => thread.id === response.id)) {
        threads.value.unshift(response);
      }
    }
    return true;
  } catch (error) {
    useAlert(error.message);
    return false;
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
      :support-agent="currentUser"
      :assistants="assistants"
      :active-assistant="activeAssistant"
      :threads="threads"
      :selected-thread-id="selectedCopilotThreadId"
      :has-more-threads="hasMoreThreads"
      :is-loading-threads="isLoadingThreads"
      :is-loading-selected-thread="isLoadingSelectedThread"
      :can-suggest-reply="canSuggestReply"
      :on-send-message="sendMessage"
      @set-assistant="setAssistant"
      @select-thread="selectThread"
      @load-more-threads="loadThreads(historyPage + 1)"
      @reset="handleReset"
    />
  </div>
  <template v-else />
</template>
