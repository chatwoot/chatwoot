import { ref, onUnmounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import LlmAPI from 'dashboard/api/saas/llm';
import LlmCableSubscription from 'dashboard/helpers/llmCable';

/**
 * Composable for real-time LLM chat with ActionCable streaming.
 *
 * Usage:
 *   const { messages, isStreaming, sendMessage, clearMessages, connect, disconnect } = useLlmChat({
 *     model: 'gpt-4.1-mini',
 *     systemPrompt: 'You are a helpful assistant.',
 *     temperature: 0.7,
 *     feature: 'assistant',
 *   });
 *
 *   connect();
 *   await sendMessage('Hello!');
 */
export function useLlmChat({
  model = 'gpt-4.1-mini',
  systemPrompt = '',
  temperature = 0.7,
  feature = 'assistant',
} = {}) {
  const store = useStore();

  const messages = ref([]);
  const isStreaming = ref(false);
  const error = ref(null);
  const activeRequestId = ref(null);

  let cable = null;

  const currentUser = () => store.getters.getCurrentUser || {};
  const accountId = () => store.getters.getCurrentAccountId;

  function handleChunk({ request_id: reqId, delta }) {
    if (reqId !== activeRequestId.value) return;
    if (!delta) return;

    const lastMsg = messages.value[messages.value.length - 1];
    if (lastMsg && lastMsg.role === 'assistant' && lastMsg.streaming) {
      lastMsg.content += delta;
    }
  }

  function handleComplete({ request_id: reqId, usage }) {
    if (reqId !== activeRequestId.value) return;

    const lastMsg = messages.value[messages.value.length - 1];
    if (lastMsg && lastMsg.role === 'assistant') {
      lastMsg.streaming = false;
      lastMsg.usage = usage;
    }
    isStreaming.value = false;
    activeRequestId.value = null;
  }

  function handleError({ request_id: reqId, error: errorMsg }) {
    if (reqId !== activeRequestId.value) return;

    const lastMsg = messages.value[messages.value.length - 1];
    if (lastMsg && lastMsg.role === 'assistant' && lastMsg.streaming) {
      lastMsg.streaming = false;
      lastMsg.error = errorMsg;
    }
    error.value = errorMsg;
    isStreaming.value = false;
    activeRequestId.value = null;
  }

  function connect() {
    if (cable) return;

    const user = currentUser();
    cable = new LlmCableSubscription({
      pubsubToken: user.pubsub_token,
      accountId: accountId(),
      onChunk: handleChunk,
      onComplete: handleComplete,
      onError: handleError,
    });
    cable.connect();
  }

  function disconnect() {
    if (cable) {
      cable.disconnect();
      cable = null;
    }
  }

  function buildApiMessages() {
    const apiMessages = [];

    if (systemPrompt) {
      apiMessages.push({ role: 'system', content: systemPrompt });
    }

    messages.value
      .filter(m => !m.error)
      .forEach(m => {
        apiMessages.push({ role: m.role, content: m.content });
      });

    return apiMessages;
  }

  async function sendMessage(content) {
    if (isStreaming.value) return;

    // Add user message
    messages.value.push({
      id: crypto.randomUUID(),
      role: 'user',
      content,
      timestamp: new Date().toISOString(),
    });

    // Add placeholder assistant message
    messages.value.push({
      id: crypto.randomUUID(),
      role: 'assistant',
      content: '',
      streaming: true,
      timestamp: new Date().toISOString(),
    });

    isStreaming.value = true;
    error.value = null;

    try {
      const apiMessages = buildApiMessages();
      // Remove the empty assistant placeholder from API messages
      apiMessages.pop();

      const { data } = await LlmAPI.completions({
        model,
        messages: apiMessages,
        stream: true,
        temperature,
        feature,
      });

      activeRequestId.value = data.request_id;
    } catch (err) {
      const lastMsg = messages.value[messages.value.length - 1];
      if (lastMsg && lastMsg.streaming) {
        lastMsg.streaming = false;
        lastMsg.error = err?.message || 'Failed to send message';
      }
      isStreaming.value = false;
    }
  }

  function clearMessages() {
    messages.value = [];
    isStreaming.value = false;
    activeRequestId.value = null;
    error.value = null;
  }

  function updateSystemPrompt(newPrompt) {
    systemPrompt = newPrompt;
  }

  function updateModel(newModel) {
    model = newModel;
  }

  onUnmounted(() => {
    disconnect();
  });

  return {
    messages,
    isStreaming,
    error,
    sendMessage,
    clearMessages,
    connect,
    disconnect,
    updateSystemPrompt,
    updateModel,
  };
}
