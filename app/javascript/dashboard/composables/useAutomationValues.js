import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import {
  getActionOptions,
  getConditionOptions,
} from 'dashboard/helper/automationHelper';

/**
 * This is a shared composables that holds utilites used to build dropdown and file options
 * @returns {Object} An object containing various automation-related functions and computed properties.
 */
export default function useAutomationValues() {
  const getters = useStoreGetters();
  const { t } = useI18n();

  const agents = useMapGetter('agents/getAgents');
  const campaigns = useMapGetter('campaigns/getAllCampaigns');
  const contacts = useMapGetter('contacts/getContacts');
  const inboxes = useMapGetter('inboxes/getInboxes');
  const labels = useMapGetter('labels/getLabels');
  const teams = useMapGetter('teams/getTeams');
  const slaPolicies = useMapGetter('sla/getSLA');

  const booleanFilterOptions = computed(() => [
    { id: true, name: t('FILTER.ATTRIBUTE_LABELS.TRUE') },
    { id: false, name: t('FILTER.ATTRIBUTE_LABELS.FALSE') },
  ]);

  const statusFilterItems = computed(() => {
    return {
      open: {
        TEXT: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT'),
      },
      resolved: {
        TEXT: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
      },
      pending: {
        TEXT: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
      },
      snoozed: {
        TEXT: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
      },
      all: {
        TEXT: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.all.TEXT'),
      },
    };
  });

  const statusFilterOptions = computed(() => {
    const statusFilters = statusFilterItems.value;
    return [
      ...Object.keys(statusFilters).map(status => ({
        id: status,
        name: statusFilters[status].TEXT,
      })),
      { id: 'all', name: t('CHAT_LIST.FILTER_ALL') },
    ];
  });

  /**
   * Gets the condition dropdown values for a given type.
   * @param {string} type - The type of condition.
   * @returns {Array} An array of condition dropdown values.
   */
  const getConditionDropdownValues = type => {
    return getConditionOptions({
      agents: agents.value,
      booleanFilterOptions: booleanFilterOptions.value,
      campaigns: campaigns.value,
      contacts: contacts.value,
      customAttributes: getters['attributes/getAttributes'].value,
      inboxes: inboxes.value,
      statusFilterOptions: statusFilterOptions.value,
      teams: teams.value,
      languages,
      countries,
      type,
    });
  };

  /**
   * Gets the action dropdown values for a given type.
   * @param {string} type - The type of action.
   * @returns {Array} An array of action dropdown values.
   */
  const getActionDropdownValues = type => {
    return getActionOptions({
      agents: agents.value,
      labels: labels.value,
      teams: teams.value,
      slaPolicies: slaPolicies.value,
      languages,
      type,
    });
  };

  return {
    booleanFilterOptions,
    statusFilterItems,
    statusFilterOptions,
    getConditionDropdownValues,
    getActionDropdownValues,
    agents,
    campaigns,
    contacts,
    inboxes,
    labels,
    teams,
    slaPolicies,
  };
}
