import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { PRIORITY_CONDITION_VALUES } from 'dashboard/constants/automation';

/**
 * Composable for handling macro-related functionality
 * @returns {Object} An object containing the getMacroDropdownValues function
 */
export const useMacros = () => {
  const getters = useStoreGetters();

  const labels = computed(() => getters['labels/getLabels'].value);
  const teams = computed(() => getters['teams/getTeams'].value);
  const agents = computed(() => getters['agents/getAgents'].value);

  /**
   * Get dropdown values based on the specified type
   * @param {string} type - The type of dropdown values to retrieve
   * @returns {Array} An array of dropdown values
   */
  const getMacroDropdownValues = type => {
    switch (type) {
      case 'assign_team':
      case 'send_email_to_team':
        return teams.value;
      case 'assign_agent':
        return [{ id: 'self', name: 'Self' }, ...agents.value];
      case 'add_label':
      case 'remove_label':
        return labels.value.map(i => ({
          id: i.title,
          name: i.title,
        }));
      case 'change_priority':
        return PRIORITY_CONDITION_VALUES;
      default:
        return [];
    }
  };

  return {
    getMacroDropdownValues,
  };
};
