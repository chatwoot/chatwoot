import { computed, onMounted } from 'vue';
import {
  useStore,
  useStoreGetters,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { OPEN_AI_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import TasksAPI from 'dashboard/api/captain/tasks';

/**
 * Cleans and normalizes a list of labels.
 * @param {string} labels - A comma-separated string of labels.
 * @returns {string[]} An array of cleaned and unique labels.
 */
const cleanLabels = labels => {
  return labels
    .toLowerCase() // Set it to lowercase
    .split(',') // split the string into an array
    .filter(label => label.trim()) // remove any empty strings
    .map(label => label.trim()) // trim the words
    .filter((label, index, self) => self.indexOf(label) === index);
};

/**
 * A composable function for AI-related operations in the dashboard.
 * @returns {Object} An object containing AI-related methods and computed properties.
 */
export function useAI() {
  const store = useStore();
  const getters = useStoreGetters();
  const { t } = useI18n();

  /**
   * Computed property for UI flags.
   * @type {import('vue').ComputedRef<Object>}
   */
  const uiFlags = computed(() => getters['integrations/getUIFlags'].value);

  const appIntegrations = useMapGetter('integrations/getAppIntegrations');
  const currentChat = useMapGetter('getSelectedChat');
  const replyMode = useMapGetter('draftMessages/getReplyEditorMode');

  /**
   * Computed property for the AI integration.
   * @type {import('vue').ComputedRef<Object|undefined>}
   */
  const aiIntegration = computed(
    () =>
      appIntegrations.value.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      )?.hooks[0]
  );

  /**
   * Computed property to check if AI integration is enabled.
   * @type {import('vue').ComputedRef<boolean>}
   */
  const isAIIntegrationEnabled = computed(() => true);

  /**
   * Computed property to check if label suggestion feature is enabled.
   * @type {import('vue').ComputedRef<boolean>}
   */
  const isLabelSuggestionFeatureEnabled = computed(() => {
    if (aiIntegration.value) {
      const { settings = {} } = aiIntegration.value || {};
      return settings.label_suggestion;
    }
    return false;
  });

  /**
   * Computed property to check if app integrations are being fetched.
   * @type {import('vue').ComputedRef<boolean>}
   */
  const isFetchingAppIntegrations = computed(() => uiFlags.value.isFetching);

  /**
   * Computed property for the conversation ID.
   * @type {import('vue').ComputedRef<string|undefined>}
   */
  const conversationId = computed(() => currentChat.value?.id);

  /**
   * Computed property for the draft key.
   * @type {import('vue').ComputedRef<string>}
   */
  const draftKey = computed(
    () => `draft-${conversationId.value}-${replyMode.value}`
  );

  /**
   * Computed property for the draft message.
   * @type {import('vue').ComputedRef<string>}
   */
  const draftMessage = computed(() =>
    getters['draftMessages/get'].value(draftKey.value)
  );

  /**
   * Fetches integrations if they haven't been loaded yet.
   * @returns {Promise<void>}
   */
  const fetchIntegrationsIfRequired = async () => {
    if (!appIntegrations.value.length) {
      await store.dispatch('integrations/get');
    }
  };

  /**
   * Records analytics for AI-related events.
   * @param {string} type - The type of event.
   * @param {Object} payload - Additional data for the event.
   * @returns {Promise<void>}
   */
  const recordAnalytics = async (type, payload) => {
    const event = OPEN_AI_EVENTS[type.toUpperCase()];
    if (event) {
      useTrack(event, {
        type,
        ...payload,
      });
    }
  };

  /**
   * Fetches label suggestions for the current conversation.
   * @returns {Promise<string[]>} An array of suggested labels.
   */
  const fetchLabelSuggestions = async () => {
    if (!conversationId.value) return [];

    try {
      const result = await TasksAPI.processEvent({
        type: 'label_suggestion',
        conversationId: conversationId.value,
      });

      const {
        data: { message: labels },
      } = result;

      return cleanLabels(labels);
    } catch {
      return [];
    }
  };

  /**
   * Processes an AI event, such as improving content.
   * @param {string} [type='improve'] - The type of AI event to process.
   * @param {string} [content=''] - The content to process (for full message) or selected text (for selection-based).
   * @param {Object} [options={}] - Additional options.
   * @param {AbortSignal} [options.signal] - AbortSignal to cancel the request.
   * @returns {Promise<{message: string, followUpContext?: Object}>} The generated message and optional follow-up context.
   */
  const processEvent = async (type = 'improve', content = '', options = {}) => {
    try {
      const result = await TasksAPI.processEvent(
        {
          type,
          content: content || draftMessage.value,
          conversationId: conversationId.value,
        },
        options.signal
      );
      const {
        data: { message: generatedMessage, follow_up_context: followUpContext },
      } = result;
      return { message: generatedMessage, followUpContext };
    } catch (error) {
      // Don't show error for aborted requests
      if (error.name === 'AbortError' || error.name === 'CanceledError') {
        return { message: '' };
      }
      const errorData = error.response?.data?.error;
      const errorMessage =
        errorData?.error?.message ||
        t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR');
      useAlert(errorMessage);
      return { message: '' };
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
      // Don't show error for aborted requests
      if (error.name === 'AbortError' || error.name === 'CanceledError') {
        return { message: '', followUpContext };
      }
      const errorData = error.response?.data?.error;
      const errorMessage =
        errorData?.error?.message ||
        t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR');
      useAlert(errorMessage);
      return { message: '', followUpContext };
    }
  };

  onMounted(() => {
    fetchIntegrationsIfRequired();
  });

  return {
    draftMessage,
    uiFlags,
    appIntegrations,
    currentChat,
    replyMode,
    isAIIntegrationEnabled,
    isLabelSuggestionFeatureEnabled,
    isFetchingAppIntegrations,
    fetchIntegrationsIfRequired,
    recordAnalytics,
    fetchLabelSuggestions,
    processEvent,
    followUp,
  };
}
