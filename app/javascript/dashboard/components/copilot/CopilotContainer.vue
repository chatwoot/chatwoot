<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'dashboard/composables/store';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import CopilotActionCableConnector from 'dashboard/helpers/CopilotActionCableConnector';
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

const messages = ref([]);
const isCaptainTyping = ref(false);
const selectedAssistantId = ref(null);
const copilotConnector = ref(null);

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
  messages.value = [];
};

const sendMessage = message => {
  // Ensure WebSocket is connected before sending
  if (!copilotConnector.value || !isSidebarOpen.value) {
    return;
  }

  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    role: 'user',
    content: message,
  });
  isCaptainTyping.value = true;

  copilotConnector.value.sendMessage({
    assistantId: activeAssistant.value.id,
    conversationId: currentChat.value?.id,
    previousHistory: messages.value
      .filter(m => m.role !== 'assistant_thinking')
      .map(m => ({
        role: m.role,
        content: m.content,
      }))
      .slice(0, -1),
    message,
  });
};

const initializeWebSocket = () => {
  copilotConnector.value = new CopilotActionCableConnector({
    accountId: currentUser.value.account_id,
    userId: currentUser.value.id,
    onDisconnect: () => {
      // copilotConnector.value = null;
    },
    onCopilotResponse: data => {
      if (data.type === 'final_response') {
        messages.value.push({
          id: new Date().getTime(),
          role: 'assistant',
          content: data.response.response,
        });
        isCaptainTyping.value = false;
      } else {
        messages.value.push({
          id: new Date().getTime(),
          role: 'assistant_thinking',
          content: data.response.response,
          reasoning: data.response.reasoning,
        });
      }
    },
  });
};

const disconnectWebSocket = () => {
  if (copilotConnector.value) {
    copilotConnector.value.disconnect();
    copilotConnector.value = null;
  }
};

onMounted(() => {
  initializeWebSocket();
  store.dispatch('captainAssistants/get');
});

onBeforeUnmount(() => {
  disconnectWebSocket();
});

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
      :is-captain-typing="isCaptainTyping"
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
