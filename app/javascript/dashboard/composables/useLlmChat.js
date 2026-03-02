import { ref, onUnmounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import LlmAPI from 'dashboard/api/saas/llm';
import LlmCableSubscription from 'dashboard/helpers/llmCable';

const STREAM_TIMEOUT_MS = 45_000; // 45 seconds

/**
 * Composable for LLM chat with optional ActionCable streaming.
 *
 * Usage (streaming via ActionCable — requires connect()):
 *   const { messages, isStreaming, sendMessage, connect, disconnect } = useLlmChat({
 *     model: 'gpt-4.1-mini',
 *     systemPrompt: 'You are a helpful assistant.',
 *     streaming: true,  // default
 *   });
 *   connect();
 *   await sendMessage('Hello!');
 *
 * Usage (non-streaming HTTP — no ActionCable needed):
 *   const { messages, isStreaming, sendMessage } = useLlmChat({
 *     model: 'gpt-4.1-mini',
 *     systemPrompt: 'You are a helpful assistant.',
 *     streaming: false,
 *   });
 *   await sendMessage('Hello!'); // resolves when HTTP response arrives
 */
export function useLlmChat({
  model = 'gpt-4.1-mini',
  systemPrompt = '',
  temperature = 0.7,
  feature = 'assistant',
  streaming = true,
} = {}) {
  const store = useStore();

  const messages = ref([]);
  const isStreaming = ref(false);
  const error = ref(null);
  const activeRequestId = ref(null);

  let cable = null;
  let streamResolve = null;
  let streamTimeoutId = null;

  const currentUser = () => store.getters.getCurrentUser || {};
  const accountId = () => store.getters.getCurrentAccountId;

  /**
   * Resolve the pending stream promise and clear timeout.
   */
  function resolveStream() {
    if (streamTimeoutId) {
      clearTimeout(streamTimeoutId);
      streamTimeoutId = null;
    }
    if (streamResolve) {
      const resolve = streamResolve;
      streamResolve = null;
      resolve();
    }
  }

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
    resolveStream();
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
    resolveStream();
  }

  function connect() {
    if (!streaming) return; // No cable needed in non-streaming mode
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

  /**
   * Send a message using non-streaming HTTP (stream: false).
   * The full response is returned in a single HTTP response.
   */
  async function sendMessageHttp(content) {
    if (isStreaming.value) return;

    // Add user message
    messages.value.push({
      id: crypto.randomUUID(),
      role: 'user',
      content,
      timestamp: new Date().toISOString(),
    });

    // Add placeholder assistant message (shown as loading)
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
        stream: false,
        temperature,
        feature,
      });

      const assistantContent =
        data?.choices?.[0]?.message?.content || data?.content || '';
      const usage = data?.usage || {};

      const lastMsg = messages.value[messages.value.length - 1];
      if (lastMsg && lastMsg.role === 'assistant') {
        lastMsg.content = assistantContent;
        lastMsg.streaming = false;
        lastMsg.usage = usage;
      }
    } catch (err) {
      const lastMsg = messages.value[messages.value.length - 1];
      if (lastMsg && lastMsg.role === 'assistant' && lastMsg.streaming) {
        lastMsg.streaming = false;
        lastMsg.error = err?.message || 'Failed to send message';
      }
      error.value = err?.message || 'Failed to send message';
    } finally {
      isStreaming.value = false;
    }
  }

  /**
   * Send a message using ActionCable streaming (stream: true).
   * Resolves when streaming finishes, errors, or times out (45s).
   */
  async function sendMessageStreaming(content) {
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

    // Promise that resolves when streaming completes, errors, or times out
    const streamCompleted = new Promise(resolve => {
      streamResolve = resolve;
    });

    // Safety timeout — unlock the UI if streaming never completes
    streamTimeoutId = setTimeout(() => {
      if (!isStreaming.value) return;
      const lastMsg = messages.value[messages.value.length - 1];
      if (lastMsg && lastMsg.streaming) {
        lastMsg.streaming = false;
        lastMsg.error = 'Response timed out. Please try again.';
      }
      isStreaming.value = false;
      activeRequestId.value = null;
      resolveStream();
    }, STREAM_TIMEOUT_MS);

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
      resolveStream();
      return;
    }

    // Wait for streaming to actually finish (or timeout)
    await streamCompleted;
  }

  /**
   * Send a user message. Delegates to streaming or non-streaming based on config.
   */
  async function sendMessage(content) {
    if (streaming) {
      await sendMessageStreaming(content);
    } else {
      await sendMessageHttp(content);
    }
  }

  function clearMessages() {
    messages.value = [];
    isStreaming.value = false;
    activeRequestId.value = null;
    error.value = null;
    resolveStream();
  }

  function updateSystemPrompt(newPrompt) {
    systemPrompt = newPrompt;
  }

  function updateModel(newModel) {
    model = newModel;
  }

  onUnmounted(() => {
    resolveStream();
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
