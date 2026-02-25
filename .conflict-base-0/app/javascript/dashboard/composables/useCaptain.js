import { computed } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import TasksAPI from 'dashboard/api/captain/tasks';
import { CAPTAIN_ERROR_TYPES } from 'dashboard/composables/captain/constants';

export function useCaptain() {
  const store = useStore();
  const { t } = useI18n();
  const { isCloudFeatureEnabled, currentAccount } = useAccount();
  const { isEnterprise } = useConfig();
  const uiFlags = useMapGetter('accounts/getUIFlags');
  const currentChat = useMapGetter('getSelectedChat');
  const replyMode = useMapGetter('draftMessages/getReplyEditorMode');
  const conversationId = computed(() => currentChat.value?.id);
  const draftKey = computed(
    () => `draft-${conversationId.value}-${replyMode.value}`
  );
  const draftMessage = useFunctionGetter('draftMessages/get', draftKey);

  // === Feature Flags ===
  const captainEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN);
  });

  const captainTasksEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_TASKS);
  });

  // === Limits (Enterprise) ===
  const captainLimits = computed(() => {
    return currentAccount.value?.limits?.captain;
  });

  const documentLimits = computed(() => {
    if (captainLimits.value?.documents) {
      return useCamelCase(captainLimits.value.documents);
    }
    return null;
  });

  const responseLimits = computed(() => {
    if (captainLimits.value?.responses) {
      return useCamelCase(captainLimits.value.responses);
    }
    return null;
  });

  const isFetchingLimits = computed(() => uiFlags.value.isFetchingLimits);

  const fetchLimits = () => {
    if (isEnterprise) {
      store.dispatch('accounts/limits');
    }
  };

  // === Error Handling ===
  /**
   * Handles API errors and displays appropriate error messages.
   * Silently returns for aborted requests.
   * @param {Error} error - The error object from the API call.
   */
  const handleAPIError = error => {
    if (
      error.name === CAPTAIN_ERROR_TYPES.ABORT_ERROR ||
      error.name === CAPTAIN_ERROR_TYPES.CANCELED_ERROR
    ) {
      return;
    }
    const errorMessage =
      error.response?.data?.error ||
      t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR');
    useAlert(errorMessage);
  };

  /**
   * Classifies API error types for downstream analytics.
   * @param {Error} error
   * @returns {string}
   */
  const getErrorType = error => {
    if (
      error.name === CAPTAIN_ERROR_TYPES.ABORT_ERROR ||
      error.name === CAPTAIN_ERROR_TYPES.CANCELED_ERROR
    ) {
      return CAPTAIN_ERROR_TYPES.ABORTED;
    }
    if (error.response?.status) {
      return `${CAPTAIN_ERROR_TYPES.HTTP_PREFIX}${error.response.status}`;
    }
    return CAPTAIN_ERROR_TYPES.API_ERROR;
  };

  // === Task Methods ===
  /**
   * Rewrites content with a specific operation.
   * @param {string} content - The content to rewrite.
   * @param {string} operation - The operation (fix_spelling_grammar, casual, professional, expand, shorten, improve, etc).
   * @param {Object} [options={}] - Additional options.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext?: Object}>} The rewritten content and optional follow-up context.
   */
  const rewriteContent = async (content, operation, options = {}) => {
    try {
      const result = await TasksAPI.rewrite(
        {
          content: content || draftMessage.value,
          operation,
          conversationId: conversationId.value,
        },
        options.signal
      );
      const {
        data: { message: generatedMessage, follow_up_context: followUpContext },
      } = result;
      return { message: generatedMessage, followUpContext };
    } catch (error) {
      handleAPIError(error);
      return { message: '', errorType: getErrorType(error) };
    }
  };

  /**
   * Summarizes a conversation.
   * @param {Object} [options={}] - Additional options.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext?: Object}>} The summary and optional follow-up context.
   */
  const summarizeConversation = async (options = {}) => {
    try {
      const result = await TasksAPI.summarize(
        conversationId.value,
        options.signal
      );
      const {
        data: { message: generatedMessage, follow_up_context: followUpContext },
      } = result;
      return { message: generatedMessage, followUpContext };
    } catch (error) {
      handleAPIError(error);
      return { message: '', errorType: getErrorType(error) };
    }
  };

  /**
   * Gets a reply suggestion for the current conversation.
   * @param {Object} [options={}] - Additional options.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext?: Object}>} The reply suggestion and optional follow-up context.
   */
  const getReplySuggestion = async (options = {}) => {
    try {
      const result = await TasksAPI.replySuggestion(
        conversationId.value,
        options.signal
      );
      const {
        data: { message: generatedMessage, follow_up_context: followUpContext },
      } = result;
      return { message: generatedMessage, followUpContext };
    } catch (error) {
      handleAPIError(error);
      return { message: '', errorType: getErrorType(error) };
    }
  };

  /**
   * Sends a follow-up message to refine a previous AI task result.
   * @param {Object} options - The follow-up options.
   * @param {Object} options.followUpContext - The follow-up context from a previous task.
   * @param {string} options.message - The follow-up message/request from the user.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext: Object}>} The follow-up response and updated context.
   */
  const followUp = async ({ followUpContext, message, signal }) => {
    try {
      const result = await TasksAPI.followUp(
        { followUpContext, message, conversationId: conversationId.value },
        signal
      );
      const {
        data: { message: generatedMessage, follow_up_context: updatedContext },
      } = result;
      return { message: generatedMessage, followUpContext: updatedContext };
    } catch (error) {
      handleAPIError(error);
      return {
        message: '',
        followUpContext,
        errorType: getErrorType(error),
      };
    }
  };

  /**
   * Processes an AI event. Routes to the appropriate method based on type.
   * @param {string} [type='improve'] - The type of AI event to process.
   * @param {string} [content=''] - The content to process.
   * @param {Object} [options={}] - Additional options.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext?: Object}>} The generated message and optional follow-up context.
   */
  const processEvent = async (type = 'improve', content = '', options = {}) => {
    if (type === 'summarize') {
      return summarizeConversation(options);
    }
    if (type === 'reply_suggestion') {
      return getReplySuggestion(options);
    }
    // All other types are rewrite operations
    return rewriteContent(content, type, options);
  };

  return {
    // Feature flags
    captainEnabled,
    captainTasksEnabled,

    // Limits (Enterprise)
    captainLimits,
    documentLimits,
    responseLimits,
    fetchLimits,
    isFetchingLimits,

    // Conversation context
    draftMessage,
    currentChat,

    // Task methods
    rewriteContent,
    summarizeConversation,
    getReplySuggestion,
    followUp,
    processEvent,
  };
}
