<script setup>
import { ref, computed, watch } from 'vue';
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
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';
import CopilotThreadsAPI from 'dashboard/api/captain/copilotThreads';

const store = useStore();
const captainConfig = useCaptainConfigStore();
const { uiSettings, updateUISettings } = useUISettings();
const { isEnterprise } = useConfig();
const { width: windowWidth } = useWindowSize();

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
let selectionVersion = 0;
let accountVersion = 0;
const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](
    selectedCopilotThreadId.value
  )
);

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const threads = ref([]);
const locallyCreatedThreadIds = new Set();
const serverThreadIds = new Set();
const historyPage = ref(0);
const hasMoreThreads = ref(false);
const isLoadingThreads = ref(false);
const selectedThread = computed(() =>
  threads.value.find(thread => thread.id === selectedCopilotThreadId.value)
);

const accountAssistants = computed(() =>
  assistants.value.filter(
    assistant =>
      !assistant.account_id ||
      Number(assistant.account_id) === Number(currentAccountId.value)
  )
);

const legacyAssistant = computed(() => {
  const preferredId = uiSettings.value.preferred_captain_assistant_id;

  // If the user has selected a specific assistant, it takes first preference for Copilot.
  if (preferredId) {
    const preferredAssistant = accountAssistants.value.find(
      assistant => assistant.id === preferredId
    );
    // Return the preferred assistant if found, otherwise continue to next cases
    if (preferredAssistant) return preferredAssistant;
  }

  // If the above is not available, the assistant connected to the inbox takes preference.
  if (inboxAssistant.value) {
    const inboxMatchedAssistant = accountAssistants.value.find(
      a => a.id === inboxAssistant.value.id
    );
    if (inboxMatchedAssistant) return inboxMatchedAssistant;
  }
  // If neither of the above is available, the first assistant in the account takes preference.
  return accountAssistants.value[0];
});
const configuredAssistant = computed(() => {
  return (
    accountAssistants.value.find(
      assistant => assistant.id === Number(captainConfig.copilotAssistantId)
    ) || legacyAssistant.value
  );
});
const activeAssistant = computed(() =>
  selectedThread.value
    ? selectedThread.value.assistant
    : configuredAssistant.value
);

const closeCopilotPanel = () => {
  if (isSmallScreen.value && uiSettings.value?.is_copilot_panel_open) {
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: false,
    });
  }
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
  return isCaptainEnabled && isCopilotPanelOpen && !uiFlags.value.fetchingList;
});

const handleReset = () => {
  selectionVersion += 1;
  selectedCopilotThreadId.value = null;
  isLoadingSelectedThread.value = false;
};

const loadThreads = async (page = 1) => {
  const version = accountVersion;
  const accountId = currentAccountId.value;
  isLoadingThreads.value = true;
  try {
    const { data } = await CopilotThreadsAPI.get({ page });
    if (
      version !== accountVersion ||
      Number(accountId) !== Number(currentAccountId.value)
    ) {
      return;
    }

    const knownIds = new Set(threads.value.map(thread => thread.id));
    if (page === 1) {
      serverThreadIds.clear();
      const localThreads = threads.value.filter(thread =>
        locallyCreatedThreadIds.has(thread.id)
      );
      const localIds = new Set(localThreads.map(thread => thread.id));
      threads.value = [
        ...localThreads,
        ...data.payload.filter(thread => !localIds.has(thread.id)),
      ];
    } else {
      threads.value = [
        ...threads.value,
        ...data.payload.filter(thread => !knownIds.has(thread.id)),
      ];
    }
    data.payload.forEach(thread => serverThreadIds.add(thread.id));
    historyPage.value = page;
    hasMoreThreads.value = serverThreadIds.size < data.meta.total_count;
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
  const accountId = currentAccountId.value;
  const previousThreadId = selectedCopilotThreadId.value;
  selectedCopilotThreadId.value = thread.id;
  isLoadingSelectedThread.value = true;
  try {
    await store.dispatch('copilotMessages/get', {
      threadId: thread.id,
      accountId,
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

watch(() => currentChat.value?.id, handleReset);

const initializeAccount = () => {
  accountVersion += 1;
  selectionVersion += 1;
  selectedCopilotThreadId.value = null;
  isLoadingSelectedThread.value = false;
  threads.value = [];
  locallyCreatedThreadIds.clear();
  serverThreadIds.clear();
  historyPage.value = 0;
  hasMoreThreads.value = false;
  isLoadingThreads.value = false;
  store.dispatch('copilotMessages/reset', currentAccountId.value);
  store.dispatch('copilotThreads/reset', currentAccountId.value);
  captainConfig.reset();

  if (!isEnterprise || !currentAccountId.value) return;

  store.dispatch('captainAssistants/get');
  captainConfig.fetch();
  loadThreads();
};

watch(currentAccountId, initializeAccount, { immediate: true, flush: 'sync' });

const sendMessage = async payload => {
  if (isLoadingSelectedThread.value) return false;

  const currentVersion = accountVersion;
  const accountId = currentAccountId.value;
  const message = typeof payload === 'string' ? payload : payload.message;
  const requestType =
    typeof payload === 'string' ? undefined : payload.requestType;

  try {
    if (selectedCopilotThreadId.value) {
      await store.dispatch('copilotMessages/create', {
        conversation_id: currentChat.value?.id,
        threadId: selectedCopilotThreadId.value,
        message,
      });
      if (
        currentVersion !== accountVersion ||
        Number(accountId) !== Number(currentAccountId.value)
      ) {
        return false;
      }
    } else {
      const conversationId = currentChat.value?.id;
      const version = selectionVersion;
      const response = await store.dispatch('copilotThreads/create', {
        assistant_id: configuredAssistant.value.id,
        conversation_id: conversationId,
        message,
        ...(requestType && { request_type: requestType }),
      });
      if (
        currentVersion !== accountVersion ||
        Number(accountId) !== Number(currentAccountId.value)
      ) {
        return false;
      }

      if (
        currentChat.value?.id === conversationId &&
        selectionVersion === version
      ) {
        selectedCopilotThreadId.value = response.id;
      }
      if (!threads.value.some(thread => thread.id === response.id)) {
        threads.value.unshift(response);
      }
      locallyCreatedThreadIds.add(response.id);
    }
    return true;
  } catch (error) {
    if (
      currentVersion === accountVersion &&
      Number(accountId) === Number(currentAccountId.value)
    ) {
      useAlert(error.message);
    }
    return false;
  }
};
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
      :key="currentAccountId"
      :messages="messages"
      :active-assistant="activeAssistant"
      :threads="threads"
      :selected-thread-id="selectedCopilotThreadId"
      :has-more-threads="hasMoreThreads"
      :is-loading-threads="isLoadingThreads"
      :is-loading-selected-thread="isLoadingSelectedThread"
      :can-suggest-reply="canSuggestReply"
      :on-send-message="sendMessage"
      @select-thread="selectThread"
      @load-more-threads="loadThreads(historyPage + 1)"
      @reset="handleReset"
    />
  </div>
  <template v-else />
</template>
