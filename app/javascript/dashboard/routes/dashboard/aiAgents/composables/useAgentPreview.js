import { computed, ref } from 'vue';
import { useLlmChat } from 'dashboard/composables/useLlmChat';
import AiAgentsAPI from 'dashboard/api/saas/aiAgents';

/**
 * Composable for testing / previewing an AI agent's responses.
 *
 * Instead of calling the raw LLM completions endpoint, it uses the
 * agent-specific preview endpoint which processes through the full
 * agent executor pipeline (structured prompt sections, tools, RAG, etc).
 */
export function useAgentPreview(agent) {
  const { messages, error, connect, disconnect, clearMessages } = useLlmChat({
    model: computed(() =>
      (agent.value?.model || 'gpt-4.1-mini').replace(/^litellm\//, '')
    ),
    systemPrompt: '',
    temperature: 0.7,
    feature: 'agent_preview',
  });

  const isStreaming = ref(false);

  /**
   * Send a message to the agent preview endpoint.
   * This goes through the full executor pipeline on the backend.
   */
  const sendPreviewMessage = async content => {
    if (!content?.trim() || isStreaming.value) return;

    isStreaming.value = true;

    const userMessage = {
      id: `user-${Date.now()}`,
      role: 'user',
      content: content.trim(),
      timestamp: Date.now(),
    };
    messages.value.push(userMessage);

    const assistantMessage = {
      id: `assistant-${Date.now()}`,
      role: 'assistant',
      content: '',
      streaming: true,
      timestamp: Date.now(),
    };
    messages.value.push(assistantMessage);

    try {
      const history = messages.value
        .filter(m => !m.streaming && m.role !== 'system')
        .map(m => ({ role: m.role, content: m.content }));

      const response = await AiAgentsAPI.preview(agent.value.id, {
        message: content.trim(),
        messages: history,
        stream: false,
      });

      assistantMessage.content =
        response.data?.reply ||
        response.data?.content ||
        response.data?.choices?.[0]?.message?.content ||
        '';
      assistantMessage.streaming = false;
    } catch (err) {
      assistantMessage.content = err?.message || 'Error generating response';
      assistantMessage.streaming = false;
      assistantMessage.error = true;
    } finally {
      isStreaming.value = false;
    }
  };

  const restart = () => {
    clearMessages();
  };

  return {
    messages,
    isStreaming,
    error,
    sendPreviewMessage,
    restart,
    connect,
    disconnect,
  };
}
