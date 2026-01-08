import { ref, computed } from 'vue';
import { useAI } from 'dashboard/composables/useAI';
import { useUISettings } from 'dashboard/composables/useUISettings';

/**
 * Composable for managing Copilot reply generation state and actions.
 * Extracts copilot-related logic from ReplyBox for cleaner code organization.
 *
 * @returns {Object} Copilot reply state and methods
 */
export function useCopilotReply() {
  const { processEvent, followUp } = useAI();
  const { updateUISettings } = useUISettings();

  const showEditor = ref(false);
  const isGenerating = ref(false);
  const isContentReady = ref(false);
  const generatedContent = ref('');
  const followUpContext = ref(null);
  const abortController = ref(null);

  const isActive = computed(() => showEditor.value || isGenerating.value);
  const isButtonDisabled = computed(
    () => isGenerating.value || !isContentReady.value
  );
  const editorTransitionKey = computed(() =>
    isActive.value ? 'copilot' : 'rich'
  );

  /**
   * Resets all copilot editor state and cancels any ongoing generation.
   */
  function reset() {
    if (abortController.value) {
      abortController.value.abort();
      abortController.value = null;
    }
    showEditor.value = false;
    isGenerating.value = false;
    isContentReady.value = false;
    generatedContent.value = '';
    followUpContext.value = null;
  }

  /**
   * Toggles the copilot editor visibility.
   */
  function toggleEditor() {
    showEditor.value = !showEditor.value;
  }

  /**
   * Marks content as ready (called after transition completes).
   */
  function setContentReady() {
    isContentReady.value = true;
  }

  /**
   * Executes a copilot action (e.g., improve, fix grammar).
   * @param {string} action - The action type
   * @param {string} data - The content to process
   */
  async function execute(action, data) {
    if (action === 'ask_copilot') {
      updateUISettings({
        is_contact_sidebar_open: false,
        is_copilot_panel_open: true,
      });
      return;
    }

    // Reset and start new generation
    reset();
    abortController.value = new AbortController();
    isGenerating.value = true;
    isContentReady.value = false;

    try {
      const { message: content, followUpContext: newContext } =
        await processEvent(action, data, {
          signal: abortController.value.signal,
        });

      if (!abortController.value?.signal.aborted) {
        generatedContent.value = content;
        followUpContext.value = newContext;
        if (content) showEditor.value = true;
        isGenerating.value = false;
      }
    } catch {
      if (!abortController.value?.signal.aborted) {
        isGenerating.value = false;
      }
    }
  }

  /**
   * Sends a follow-up message to refine the current generated content.
   * @param {string} message - The follow-up message from the user
   */
  async function sendFollowUp(message) {
    if (!followUpContext.value || !message.trim()) return;

    abortController.value = new AbortController();
    isGenerating.value = true;
    isContentReady.value = false;

    try {
      const { message: content, followUpContext: updatedContext } =
        await followUp({
          followUpContext: followUpContext.value,
          message,
          signal: abortController.value.signal,
        });

      if (!abortController.value?.signal.aborted) {
        generatedContent.value = content;
        followUpContext.value = updatedContext;
        if (content) showEditor.value = true;
        isGenerating.value = false;
      }
    } catch {
      if (!abortController.value?.signal.aborted) {
        isGenerating.value = false;
      }
    }
  }

  /**
   * Accepts the generated content and returns it.
   * Note: Formatting is automatically stripped by the Editor component's
   * createState function based on the channel's schema.
   * @returns {string} The content ready for the editor
   */
  function accept() {
    const content = generatedContent.value;
    showEditor.value = false;
    return content;
  }

  return {
    showEditor,
    isGenerating,
    isContentReady,
    generatedContent,
    followUpContext,

    isActive,
    isButtonDisabled,
    editorTransitionKey,

    reset,
    toggleEditor,
    setContentReady,
    execute,
    sendFollowUp,
    accept,
  };
}
