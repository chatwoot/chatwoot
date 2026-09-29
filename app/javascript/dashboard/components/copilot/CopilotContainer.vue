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

const threads = ref([]);
const historyPage = ref(0);
const hasMoreThreads = ref(false);
const isLoadingThreads = ref(false);
const selectedThread = computed(() =>
  threads.value.find(thread => thread.id === selectedCopilotThreadId.value)
);

const legacyAssistant = computed(() => {
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
const configuredAssistant = computed(() => {
  return (
    assistants.value.find(
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
};

const loadThreads = async (page = 1) => {
  isLoadingThreads.value = true;
  try {
    const { data } = await CopilotThreadsAPI.get({ page });
    const knownIds = new Set(threads.value.map(thread => thread.id));
    threads.value =
      page === 1
        ? data.payload
        : [
            ...threads.value,
            ...data.payload.filter(thread => !knownIds.has(thread.id)),
          ];
    historyPage.value = page;
    hasMoreThreads.value = threads.value.length < data.meta.total_count;
  } catch (error) {
    useAlert(error.message);
  } finally {
    isLoadingThreads.value = false;
  }
};

const selectThread = async thread => {
  selectionVersion += 1;
  const version = selectionVersion;
  try {
    await store.dispatch('copilotMessages/get', thread.id);
    if (selectionVersion === version) selectedCopilotThreadId.value = thread.id;
  } catch (error) {
    useAlert(error.message);
  }
};

watch(() => currentChat.value?.id, handleReset);

const sendMessage = async payload => {
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
        currentChat.value?.id === conversationId &&
        selectionVersion === version
      ) {
        selectedCopilotThreadId.value = response.id;
      }
      threads.value.unshift(response);
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
    captainConfig.fetch();
    loadThreads();
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
      :active-assistant="activeAssistant"
      :threads="threads"
      :selected-thread-id="selectedCopilotThreadId"
      :has-more-threads="hasMoreThreads"
      :is-loading-threads="isLoadingThreads"
      :can-suggest-reply="canSuggestReply"
      :on-send-message="sendMessage"
      @select-thread="selectThread"
      @load-more-threads="loadThreads(historyPage + 1)"
      @reset="handleReset"
    />
  </div>
  <template v-else />
</template>
