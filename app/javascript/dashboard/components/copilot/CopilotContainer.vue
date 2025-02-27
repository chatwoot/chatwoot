<script setup>
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { ref, onMounted, computed, onUnmounted } from 'vue';
import CaptainAssistantAPI from 'dashboard/api/captain/assistant';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
});

const currentUser = useMapGetter('getCurrentUser');
const { uiSettings, updateUISettings } = useUISettings();
const messages = ref([]);
const isCaptainTyping = ref(false);
const assistants = ref([]);
const isLoadingAssistants = ref(false);
const selectedAssistantId = ref(null);
const hasError = ref(false);
const isDropdownOpen = ref(false);
const inboxHasAssistant = ref(false);
const inboxAssistantId = ref(null);

// Computed property to check if we have assistants
const hasAssistants = computed(() => assistants.value.length > 0);

// Computed property to check if an assistant is available (either selected or from inbox)
const isAssistantAvailable = computed(() => {
  return selectedAssistantId.value || inboxHasAssistant.value;
});

// Fetch all available assistants
const fetchAssistants = async () => {
  isLoadingAssistants.value = true;
  try {
    const { data } = await CaptainAssistantAPI.getAll();
    assistants.value = data.payload;
  } catch {
    // Error will be shown in the UI via hasError state
    hasError.value = true;
  } finally {
    isLoadingAssistants.value = false;
  }
};

// Save the selected assistant as the user's preference
const saveAssistantPreference = async () => {
  try {
    await updateUISettings({
      preferred_captain_assistant_id: selectedAssistantId.value,
    });
  } catch {
    // Error will be shown in the UI via hasError state
    hasError.value = true;
  }
};

// Check if the inbox has an assistant connected
const checkInboxAssistant = async () => {
  try {
    const { data } = await ConversationAPI.getInboxAssistant(
      props.conversationId
    );
    if (data && data.assistant) {
      inboxHasAssistant.value = true;
      inboxAssistantId.value = data.assistant.id;
    }

    // Set the selected assistant based on priority:
    // 1. User preference if exists
    // 2. Inbox assistant if exists
    // 3. Null (no selection) if neither exists
    if (uiSettings.value.preferred_captain_assistant_id) {
      selectedAssistantId.value =
        uiSettings.value.preferred_captain_assistant_id;
    } else if (inboxHasAssistant.value) {
      selectedAssistantId.value = inboxAssistantId.value;
    } else {
      selectedAssistantId.value = null;
    }
  } catch {
    // If we can't check the inbox assistant, fall back to user preference
    selectedAssistantId.value =
      uiSettings.value.preferred_captain_assistant_id || null;
    hasError.value = true;
  }
};

// Close dropdown when clicking outside
const handleClickOutside = event => {
  const dropdown = document.querySelector('.custom-dropdown');
  if (dropdown && !dropdown.contains(event.target)) {
    isDropdownOpen.value = false;
  }
};

// Select an assistant and save preference
const selectAssistant = async assistantId => {
  selectedAssistantId.value = assistantId;
  isDropdownOpen.value = false;
  await saveAssistantPreference();
};

const handleReset = () => {
  messages.value = [];
};

const sendMessage = async message => {
  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    role: 'user',
    content: message,
  });
  isCaptainTyping.value = true;

  try {
    const { data } = await ConversationAPI.requestCopilot(
      props.conversationId,
      {
        previous_history: messages.value
          .map(m => ({
            role: m.role,
            content: m.content,
          }))
          .slice(0, -1),
        message,
        assistant_id: selectedAssistantId.value,
      }
    );
    messages.value.push({
      id: new Date().getTime(),
      role: 'assistant',
      content: data.message,
    });
  } catch {
    hasError.value = true;
  } finally {
    isCaptainTyping.value = false;
  }
};

// Add and remove event listener for click outside
onMounted(() => {
  document.addEventListener('click', handleClickOutside);
  fetchAssistants();
  checkInboxAssistant();
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});
</script>

<template>
  <div class="copilot-container">
    <div v-if="hasAssistants" class="assistant-selector">
      <div class="selector-content">
        <label class="selector-label">{{
          $t('COPILOT.SELECT_ASSISTANT')
        }}</label>
        <div class="custom-dropdown">
          <button
            type="button"
            class="dropdown-button"
            @click="isDropdownOpen = !isDropdownOpen"
          >
            <span v-if="selectedAssistantId">
              {{ assistants.find(a => a.id === selectedAssistantId)?.name }}
            </span>
            <span v-else-if="inboxHasAssistant">
              {{ $t('COPILOT.USE_INBOX_ASSISTANT') }}
            </span>
            <span v-else>
              {{ $t('COPILOT.SELECT_AN_ASSISTANT') }}
            </span>
            <span class="dropdown-arrow">
              <svg
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M4 6L8 10L12 6"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
            </span>
          </button>
          <div v-if="isDropdownOpen" class="dropdown-menu">
            <div
              v-if="inboxHasAssistant"
              class="dropdown-item"
              :class="{ active: !selectedAssistantId }"
              @click="selectAssistant(null)"
            >
              {{ $t('COPILOT.USE_INBOX_ASSISTANT') }}
            </div>
            <div
              v-for="assistant in assistants"
              :key="assistant.id"
              class="dropdown-item"
              :class="{ active: selectedAssistantId === assistant.id }"
              @click="selectAssistant(assistant.id)"
            >
              {{ assistant.name }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="!hasAssistants || (!isAssistantAvailable && !hasError)"
      class="no-assistant-message"
    >
      <p>{{ $t('COPILOT.NO_ASSISTANT_MESSAGE') }}</p>
      <p class="secondary-message">
        {{ $t('COPILOT.NO_ASSISTANT_DESCRIPTION') }}
      </p>
    </div>

    <Copilot
      v-else
      :messages="messages"
      :support-agent="currentUser"
      :is-captain-typing="isCaptainTyping"
      :conversation-inbox-type="conversationInboxType"
      @send-message="sendMessage"
      @reset="handleReset"
    />
  </div>
</template>

<style scoped>
.copilot-container {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.assistant-selector {
  padding: 8px 16px;
  border-bottom: 1px solid var(--s-200);
  background-color: var(--white);
}

.selector-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.selector-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--s-700);
  white-space: nowrap;
}

.custom-dropdown {
  position: relative;
  width: 100%;
  max-width: 350px;
}

.dropdown-button {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 6px 12px;
  border: 1px solid var(--s-300);
  border-radius: 4px;
  font-size: 0.875rem;
  background-color: var(--white);
  color: var(--s-800);
  cursor: pointer;
  transition: all 0.2s ease;
  height: 36px;
  text-align: left;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.dropdown-button > span:first-child {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
  min-width: 0;
}

.dropdown-arrow {
  display: flex;
  align-items: center;
  color: var(--s-600);
  margin-left: 8px;
  flex-shrink: 0;
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  width: 100%;
  background-color: var(--white);
  border: 1px solid var(--s-300);
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  z-index: 10;
  max-height: 200px;
  overflow-y: auto;
}

.dropdown-item {
  padding: 8px 12px;
  font-size: 0.875rem;
  color: var(--s-800);
  cursor: pointer;
  transition: background-color 0.2s;
}

.dropdown-item:hover {
  background-color: var(--s-100);
}

.dropdown-item.active {
  background-color: var(--s-100);
  font-weight: 500;
}

.no-assistant-message {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 2rem;
  text-align: center;
  color: var(--s-700);
}

.no-assistant-message p {
  margin-bottom: 0.5rem;
  font-size: 1rem;
}

.secondary-message {
  font-size: 0.875rem;
  color: var(--s-500);
  max-width: 300px;
}
</style>
