<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';

const store = useStore();
const currentUser = useMapGetter('getCurrentUser');
const assistants = useMapGetter('captainAssistants/getRecords');
const inboxAssistant = useMapGetter('getCopilotAssistant');
const { uiSettings, updateUISettings } = useUISettings();
const currentChat = useMapGetter('getSelectedChat');

const getUIState = useMapGetter('uiState/getUIState');
const isSidebarOpen = computed(() => getUIState.value('isCopilotSidebarOpen'));
const selectedCopilotThreadId = computed(() =>
  getUIState.value('selectedCopilotThreadId')
);
const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](
    selectedCopilotThreadId.value
  )
);
const selectedAssistantId = ref(null);

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

const handleReset = () => {
  store.dispatch('uiState/set', { selectedCopilotThreadId: null });
};

const sendMessage = async message => {
  if (!isSidebarOpen.value) {
    return;
  }

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
    store.dispatch('uiState/set', { selectedCopilotThreadId: response.id });
  }
};

onMounted(() => store.dispatch('captainAssistants/get'));

const handleClose = () => {
  store.dispatch('uiState/set', { isCopilotSidebarOpen: false });
};
</script>

<template>
  <div
    v-if="isSidebarOpen"
    class="border-l border-n-weak w-[20rem] min-w-[20rem]"
  >
    <Copilot
      :messages="messages"
      :support-agent="currentUser"
      :is-captain-typing="
        messages[messages.length - 1]?.message_type !== 'assistant'
      "
      :conversation-inbox-type="conversationInboxType"
      :assistants="assistants"
      :active-assistant="activeAssistant"
      @set-assistant="setAssistant"
      @send-message="sendMessage"
      @reset="handleReset"
      @close="handleClose"
    />
  </div>
  <div v-else class="hidden" />
</template>
