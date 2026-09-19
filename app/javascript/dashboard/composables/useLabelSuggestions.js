import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { CAPTAIN_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import wootConstants from 'dashboard/constants/globals';
import TasksAPI from 'dashboard/api/captain/tasks';

/**
 * Cleans and normalizes a list of labels.
 * @param {string} labels - A comma-separated string of labels.
 * @returns {string[]} An array of cleaned and unique labels.
 */
const cleanLabels = labels => {
  return labels
    .toLowerCase()
    .split(',')
    .filter(label => label.trim())
    .map(label => label.trim())
    .filter((label, index, self) => self.indexOf(label) === index);
};

// Shared across every caller (sidebar, command bar) so each conversation is fetched once
const suggestedTitles = ref([]);
const fetchedConversationId = ref(null);

/**
 * Fetches AI label suggestions for the selected conversation and tracks
 * which of them are still pending (suggested but not yet applied).
 */
export function useLabelSuggestions() {
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const currentChat = useMapGetter('getSelectedChat');
  const conversationId = computed(() => currentChat.value?.id);
  const { accountLabels, savedLabels } = useConversationLabels();
  const { isCloudFeatureEnabled } = useAccount();

  const isLabelSuggestionEnabled = computed(() =>
    isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_LABEL_CLASSIFIER)
  );

  // Keep the backend order, which is highest confidence first
  const pendingLabels = computed(() =>
    suggestedTitles.value
      .filter(title => !savedLabels.value.includes(title))
      .map(title => accountLabels.value.find(label => label.title === title))
      .filter(Boolean)
  );

  const fetchSuggestions = async ({ force = false } = {}) => {
    const id = conversationId.value;
    const chat = currentChat.value;
    if (!force && fetchedConversationId.value === id) return;

    fetchedConversationId.value = id;
    suggestedTitles.value = [];

    // eslint-disable-next-line no-console
    console.log('[LabelSuggestions] fetchSuggestions', {
      conversationId: id,
      status: chat?.status,
      isLabelSuggestionEnabled: isLabelSuggestionEnabled.value,
      existingLabels: chat?.labels,
    });

    if (!isLabelSuggestionEnabled.value) return;
    if (chat?.status !== wootConstants.STATUS_TYPE.OPEN) return;
    if (chat?.labels?.length) return;

    try {
      // eslint-disable-next-line no-console
      console.log('[LabelSuggestions] requesting suggestions from backend');
      const { data } = await TasksAPI.labelSuggestion(id);
      const titles = cleanLabels(data.message);
      // eslint-disable-next-line no-console
      console.log('[LabelSuggestions] received', titles);

      // Ignore responses for a conversation the agent has already left
      if (id === fetchedConversationId.value) suggestedTitles.value = titles;
    } catch {
      suggestedTitles.value = [];
    }
  };

  /**
   * Records that a label was applied, if it was one of the pending suggestions.
   * @param {Object} label - The label that was added to the conversation
   */
  const trackIfSuggested = label => {
    if (!pendingLabels.value.some(({ title }) => title === label.title)) return;
    useTrack(CAPTAIN_EVENTS.LABEL_SUGGESTION_APPLIED, {
      conversationId: conversationId.value,
      account: currentAccountId.value,
      suggestions: suggestedTitles.value,
      labelsApplied: [label.title],
    });
  };

  watch(conversationId, () => fetchSuggestions(), { immediate: true });

  onMounted(() => {
    // Debug: run label suggestions for the open conversation from the browser console
    window.suggest = () => fetchSuggestions({ force: true });
  });

  onUnmounted(() => {
    delete window.suggest;
  });

  return {
    pendingLabels,
    trackIfSuggested,
  };
}
