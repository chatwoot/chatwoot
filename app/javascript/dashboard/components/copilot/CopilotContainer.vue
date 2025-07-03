<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
defineProps({
  conversationInboxType: {
    type: String,
    default: '',
  },
});

const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const inboxAssistant = useMapGetter('getCopilotAssistant');
const currentChat = useMapGetter('getSelectedChat');

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

const selectedAssistantId = ref(null);
const { uiSettings, updateUISettings } = useUISettings();

const activeAssistant = computed(() => {
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

const setAssistant = async assistant => {
  selectedAssistantId.value = assistant.id;
  await updateUISettings({
    preferred_captain_assistant_id: assistant.id,
  });
};

const shouldShowCopilotPanel = computed(() => {
  const isCaptainEnabled = isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
  const { is_copilot_panel_open: isCopilotPanelOpen } = uiSettings.value;
  return isCaptainEnabled && isCopilotPanelOpen && !uiFlags.value.fetchingList;
});

const handleReset = () => {
  selectedCopilotThreadId.value = null;
};

const sendMessage = async message => {
  if (selectedCopilotThreadId.value) {
    await store.dispatch('copilotMessages/create', {
      assistant_id: activeAssistant.value.id,
      conversation_id: currentChat.value?.id,
      threadId: selectedCopilotThreadId.value,
      message,
    });
  } else {
    const response = await store.dispatch('copilotThreads/create', {
      assistant_id: activeAssistant.value.id,
      conversation_id: currentChat.value?.id,
      message,
    });
    selectedCopilotThreadId.value = response.id;
  }
};

onMounted(() => {
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <div
    v-if="shouldShowCopilotPanel"
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-[320px] min-w-[320px] 2xl:min-w-[360px] 2xl:w-[360px] flex flex-col bg-n-background"
  >
    <Copilot
      :messages="messages"
      :support-agent="currentUser"
      :conversation-inbox-type="conversationInboxType"
      :assistants="assistants"
      :active-assistant="activeAssistant"
      @set-assistant="setAssistant"
      @send-message="sendMessage"
      @reset="handleReset"
    />
  </div>
  <template v-else />
</template>
