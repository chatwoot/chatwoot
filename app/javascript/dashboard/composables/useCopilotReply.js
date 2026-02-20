import { ref, computed } from 'vue';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useTrack } from 'dashboard/composables';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  CAPTAIN_ERROR_TYPES,
  CAPTAIN_GENERATION_FAILURE_REASONS,
} from 'dashboard/composables/captain/constants';

// Actions that map to REWRITE events (with operation attribute)
const REWRITE_ACTIONS = [
  'improve',
  'fix_spelling_grammar',
  'casual',
  'professional',
  'expand',
  'shorten',
  'rephrase',
  'make_friendly',
  'make_formal',
  'simplify',
];

/**
 * Gets the event key suffix based on action type.
 * @param {string} action - The action type
 * @returns {string} The event key prefix (REWRITE, SUMMARIZE, or REPLY_SUGGESTION)
 */
function getEventPrefix(action) {
  if (action === 'summarize') return 'SUMMARIZE';
  if (action === 'reply_suggestion') return 'REPLY_SUGGESTION';
  return 'REWRITE';
}

/**
 * Builds the analytics payload based on action type.
 * @param {string} action - The action type
 * @param {number} conversationId - The conversation ID
 * @param {number} [followUpCount] - Optional follow-up count
 * @returns {Object} The payload object
 */
function buildPayload(action, conversationId, followUpCount = undefined) {
  const payload = { conversationId };

  // Add operation for rewrite actions
  if (REWRITE_ACTIONS.includes(action)) {
    payload.operation = action;
  }

  // Add followUpCount if provided
  if (followUpCount !== undefined) {
    payload.followUpCount = followUpCount;
  }

  return payload;
}

function trackGenerationFailure({
  action,
  conversationId,
  followUpCount = undefined,
  stage,
  reason,
}) {
  useTrack(CAPTAIN_EVENTS.GENERATION_FAILED, {
    ...buildPayload(action, conversationId, followUpCount),
    stage,
    reason,
  });
}

/**
 * Composable for managing Copilot reply generation state and actions.
 * Extracts copilot-related logic from ReplyBox for cleaner code organization.
 *
 * @returns {Object} Copilot reply state and methods
 */
export function useCopilotReply() {
  const { processEvent, followUp, currentChat } = useCaptain();
  const { updateUISettings } = useUISettings();

  const showEditor = ref(false);
  const isGenerating = ref(false);
  const isContentReady = ref(false);
  const generatedContent = ref('');
  const followUpContext = ref(null);
  const abortController = ref(null);

  // Tracking state
  const currentAction = ref(null);
  const followUpCount = ref(0);
  const trackedConversationId = ref(null);

  const conversationId = computed(() => currentChat.value?.id);

  const isActive = computed(() => showEditor.value || isGenerating.value);
  const isButtonDisabled = computed(
    () => isGenerating.value || !isContentReady.value
  );
  const editorTransitionKey = computed(() =>
    isActive.value ? 'copilot' : 'rich'
  );

  /**
   * Resets all copilot editor state and cancels any ongoing generation.
   * @param {boolean} [trackDismiss=true] - Whether to track dismiss event
   */
  function reset(trackDismiss = true) {
    // Track dismiss event if there was content and we're not accepting
    if (trackDismiss && generatedContent.value && currentAction.value) {
      const eventKey = `${getEventPrefix(currentAction.value)}_DISMISSED`;
      useTrack(
        CAPTAIN_EVENTS[eventKey],
        buildPayload(
          currentAction.value,
          trackedConversationId.value,
          followUpCount.value
        )
      );
    }

    if (abortController.value) {
      abortController.value.abort();
      abortController.value = null;
    }
    showEditor.value = false;
    isGenerating.value = false;
    isContentReady.value = false;
    generatedContent.value = '';
    followUpContext.value = null;
    currentAction.value = null;
    followUpCount.value = 0;
    trackedConversationId.value = null;
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

    // Reset without tracking dismiss (starting new action)
    reset(false);
    const requestController = new AbortController();
    abortController.value = requestController;
    isGenerating.value = true;
    isContentReady.value = false;
    currentAction.value = action;
    followUpCount.value = 0;
    trackedConversationId.value = conversationId.value;

    try {
      const {
        message: content,
        followUpContext: newContext,
        errorType,
      } = await processEvent(action, data, {
        signal: requestController.signal,
      });

      if (requestController.signal.aborted) return;
      if (errorType === CAPTAIN_ERROR_TYPES.ABORTED) {
        if (abortController.value === requestController) {
          isGenerating.value = false;
        }
        return;
      }

      generatedContent.value = content;
      followUpContext.value = newContext;
      if (content) {
        showEditor.value = true;
        // Track "Used" event on successful generation
        const eventKey = `${getEventPrefix(action)}_USED`;
        useTrack(
          CAPTAIN_EVENTS[eventKey],
          buildPayload(action, trackedConversationId.value)
        );
      } else if (errorType && errorType !== CAPTAIN_ERROR_TYPES.ABORTED) {
        trackGenerationFailure({
          action,
          conversationId: trackedConversationId.value,
          stage: 'initial',
          reason: errorType,
        });
      } else {
        trackGenerationFailure({
          action,
          conversationId: trackedConversationId.value,
          stage: 'initial',
          reason: CAPTAIN_GENERATION_FAILURE_REASONS.EMPTY_RESPONSE,
        });
      }
      isGenerating.value = false;
    } catch (error) {
      if (
        requestController.signal.aborted ||
        error?.name === CAPTAIN_ERROR_TYPES.ABORT_ERROR ||
        error?.name === CAPTAIN_ERROR_TYPES.CANCELED_ERROR
      ) {
        return;
      }
      trackGenerationFailure({
        action,
        conversationId: trackedConversationId.value,
        stage: 'initial',
        reason: error?.name || CAPTAIN_GENERATION_FAILURE_REASONS.EXCEPTION,
      });
      isGenerating.value = false;
    } finally {
      if (abortController.value === requestController) {
        abortController.value = null;
      }
    }
  }

  /**
   * Sends a follow-up message to refine the current generated content.
   * @param {string} message - The follow-up message from the user
   */
  async function sendFollowUp(message) {
    if (!followUpContext.value || !message.trim()) return;

    const requestController = new AbortController();
    abortController.value = requestController;
    isGenerating.value = true;
    isContentReady.value = false;

    // Track follow-up sent event
    useTrack(CAPTAIN_EVENTS.FOLLOW_UP_SENT, {
      conversationId: trackedConversationId.value,
    });
    followUpCount.value += 1;

    try {
      const {
        message: content,
        followUpContext: updatedContext,
        errorType,
      } = await followUp({
        followUpContext: followUpContext.value,
        message,
        signal: requestController.signal,
      });

      if (requestController.signal.aborted) return;
      if (errorType === CAPTAIN_ERROR_TYPES.ABORTED) {
        if (abortController.value === requestController) {
          isGenerating.value = false;
        }
        return;
      }

      if (content) {
        generatedContent.value = content;
        followUpContext.value = updatedContext;
        showEditor.value = true;
      } else if (errorType && errorType !== CAPTAIN_ERROR_TYPES.ABORTED) {
        trackGenerationFailure({
          action: currentAction.value,
          conversationId: trackedConversationId.value,
          followUpCount: followUpCount.value,
          stage: 'follow_up',
          reason: errorType,
        });
      } else {
        trackGenerationFailure({
          action: currentAction.value,
          conversationId: trackedConversationId.value,
          followUpCount: followUpCount.value,
          stage: 'follow_up',
          reason: CAPTAIN_GENERATION_FAILURE_REASONS.EMPTY_RESPONSE,
        });
      }
      isGenerating.value = false;
    } catch (error) {
      if (
        requestController.signal.aborted ||
        error?.name === CAPTAIN_ERROR_TYPES.ABORT_ERROR ||
        error?.name === CAPTAIN_ERROR_TYPES.CANCELED_ERROR
      ) {
        return;
      }
      trackGenerationFailure({
        action: currentAction.value,
        conversationId: trackedConversationId.value,
        followUpCount: followUpCount.value,
        stage: 'follow_up',
        reason: error?.name || CAPTAIN_GENERATION_FAILURE_REASONS.EXCEPTION,
      });
      isGenerating.value = false;
    } finally {
      if (abortController.value === requestController) {
        abortController.value = null;
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

    // Track "Applied" event
    if (currentAction.value) {
      const eventKey = `${getEventPrefix(currentAction.value)}_APPLIED`;
      useTrack(
        CAPTAIN_EVENTS[eventKey],
        buildPayload(
          currentAction.value,
          trackedConversationId.value,
          followUpCount.value
        )
      );
    }

    // Reset state without tracking dismiss
    showEditor.value = false;
    generatedContent.value = '';
    followUpContext.value = null;
    currentAction.value = null;
    followUpCount.value = 0;
    trackedConversationId.value = null;

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
