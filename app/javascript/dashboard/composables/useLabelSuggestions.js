import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
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

export function useLabelSuggestions() {
  const globalConfig = useMapGetter('globalConfig/get');
  const currentChat = useMapGetter('getSelectedChat');
  const conversationId = computed(() => currentChat.value?.id);

  const isLabelSuggestionEnabled = computed(
    () => globalConfig.value.labelSuggestionsEnabled
  );

  /**
   * Gets label suggestions for the current conversation.
   * @returns {Promise<string[]>} An array of suggested labels.
   */
  const getLabelSuggestions = async () => {
    if (!conversationId.value) return [];

    try {
      const result = await TasksAPI.labelSuggestion(conversationId.value);
      const {
        data: { message: labels },
      } = result;
      return cleanLabels(labels);
    } catch {
      return [];
    }
  };

  return {
    isLabelSuggestionEnabled,
    getLabelSuggestions,
  };
}
