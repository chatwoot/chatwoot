<script setup>
import { ref, onMounted, watch } from 'vue';
import MessageList from '../../../ui/MessageList.vue';

// Props that become Web Component attributes
const props = defineProps({
  conversationId: {
    type: [String, Number],
    required: true,
  },
});

// Internal state
const isInitialized = ref(false);
const error = ref(null);

async function waitForGlobalInitialization() {
  // Wait for global Chatwoot objects to be available
  let attempts = 0;
  const maxAttempts = 5000; // 5 seconds max wait

  while (attempts < maxAttempts) {
    // eslint-disable-next-line no-underscore-dangle
    if (window.__CHATWOOT_STORE__ && window.WootConstants) {
      return;
    }

    // eslint-disable-next-line no-await-in-loop
    await new Promise(resolve => {
      // eslint-disable-next-line no-promise-executor-return
      return setTimeout(resolve, 100);
    });

    attempts += 1;
  }

  throw new Error('Chatwoot global initialization timed out');
}

function updateConversationId() {
  if (props.conversationId) {
    // eslint-disable-next-line no-underscore-dangle
    window.__WOOT_CONVERSATION_ID__ = Number(props.conversationId);
  }
}

onMounted(async () => {
  try {
    // Wait for global initialization (done by Provider)
    await waitForGlobalInitialization();

    isInitialized.value = true;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('Failed to initialize MessageList:', err);
    error.value = err.message;
  }
});

// Watch for conversation ID changes
watch(
  () => props.conversationId,
  () => {
    if (isInitialized.value) {
      updateConversationId();
    }
  },
  {
    immediate: true,
  }
);
</script>

<template>
  <div class="chatwoot-message-list-container">
    <!-- Loading state -->
    <div v-if="!isInitialized && !error" class="chatwoot-loading">
      <div class="flex items-center justify-center h-full">
        <div class="text-center">
          <div
            class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-2"
          />
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          <p class="text-sm text-gray-600">Loading conversation...</p>
        </div>
      </div>
    </div>

    <!-- Error state -->
    <div v-else-if="error" class="chatwoot-error">
      <div class="flex items-center justify-center h-full">
        <div class="text-center p-4">
          <div class="text-red-500 mb-2">
            <svg
              class="w-8 h-8 mx-auto"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L3.732 15.5c-.77.833.192 2.5 1.732 2.5z"
              />
            </svg>
          </div>
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          <p class="text-sm text-gray-600">Failed to load conversation</p>
          <p class="text-xs text-gray-400 mt-1">{{ error }}</p>
        </div>
      </div>
    </div>

    <!-- Main MessageList component -->
    <div v-else-if="isInitialized" class="chatwoot-message-list">
      <MessageList />
    </div>
  </div>
</template>

<style>
/* Import all necessary styles for the MessageList */
@import '../../../dashboard/assets/scss/app.scss';
@import 'vue-multiselect/dist/vue-multiselect.css';
@import 'floating-vue/dist/style.css';

.chatwoot-message-list-container {
  height: 100%;
  width: 100%;
  position: relative;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
}

.chatwoot-loading,
.chatwoot-error {
  height: 100%;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chatwoot-message-list {
  height: 100%;
  width: 100%;
}

/* Ensure proper containment */
.chatwoot-message-list-container {
  contain: layout style;
}
</style>
