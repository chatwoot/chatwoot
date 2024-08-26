import { computed } from 'vue';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from './useI18n';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';
import countries from 'shared/constants/countries';
import {
  generateCustomAttributeTypes,
  getActionOptions,
  getConditionOptions,
  getCustomAttributeInputType,
  getDefaultConditions,
  getDefaultActions,
  filterCustomAttributes,
  getStandardAttributeInputType,
  isCustomAttribute,
  generateCustomAttributes,
} from 'dashboard/helper/automationHelper';

/**
 * Composable for handling automation-related functionality.
 * @returns {Object} An object containing various automation-related functions and computed properties.
 */
export function useAutomation() {
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

  const statusFilterOptions = computed(() => {
    const statusFilters = t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS');
    return [
      ...Object.keys(statusFilters).map(status => ({
        id: status,
        name: statusFilters[status].TEXT,
      })),
      { id: 'all', name: t('CHAT_LIST.FILTER_ALL') },
    ];
  });

  /**
   * Handles the event change for an automation.
   * @param {Object} automation - The automation object to update.
   */
  const onEventChange = automation => {
    automation.conditions = getDefaultConditions(automation.event_name);
    automation.actions = getDefaultActions();
  };

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
   * Appends a new condition to the automation.
   * @param {Object} automation - The automation object to update.
   */
  const appendNewCondition = automation => {
    automation.conditions.push(...getDefaultConditions(automation.event_name));
  };

  /**
   * Appends a new action to the automation.
   * @param {Object} automation - The automation object to update.
   */
  const appendNewAction = automation => {
    automation.actions.push(...getDefaultActions());
  };

  /**
   * Removes a filter from the automation.
   * @param {Object} automation - The automation object to update.
   * @param {number} index - The index of the filter to remove.
   */
  const removeFilter = (automation, index) => {
    if (automation.conditions.length <= 1) {
      useAlert(t('AUTOMATION.CONDITION.DELETE_MESSAGE'));
    } else {
      automation.conditions.splice(index, 1);
    }
  };

  /**
   * Removes an action from the automation.
   * @param {Object} automation - The automation object to update.
   * @param {number} index - The index of the action to remove.
   */
  const removeAction = (automation, index) => {
    if (automation.actions.length <= 1) {
      useAlert(t('AUTOMATION.ACTION.DELETE_MESSAGE'));
    } else {
      automation.actions.splice(index, 1);
    }
  };

  /**
   * Resets a filter in the automation.
   * @param {Object} automation - The automation object to update.
   * @param {Object} automationTypes - The automation types object.
   * @param {number} index - The index of the filter to reset.
   * @param {Object} currentCondition - The current condition object.
   */
  const resetFilter = (
    automation,
    automationTypes,
    index,
    currentCondition
  ) => {
    automation.conditions[index].filter_operator = automationTypes[
      automation.event_name
    ].conditions.find(
      condition => condition.key === currentCondition.attribute_key
    ).filterOperators[0].value;
    automation.conditions[index].values = '';
  };

  /**
   * Resets an action in the automation.
   * @param {Object} automation - The automation object to update.
   * @param {number} index - The index of the action to reset.
   */
  const resetAction = (automation, index) => {
    automation.actions[index].action_params = [];
  };

  /**
   * This function sets the conditions for automation.
   * It help to format the conditions for the automation when we open the edit automation modal.
   * @param {Object} automation - The automation object containing conditions to manifest.
   * @param {Array} allCustomAttributes - List of all custom attributes.
   * @param {Object} automationTypes - Object containing automation type definitions.
   * @returns {Array} An array of manifested conditions.
   */
  const manifestConditions = (
    automation,
    allCustomAttributes,
    automationTypes
  ) => {
    const customAttributes = filterCustomAttributes(allCustomAttributes);
    return automation.conditions.map(condition => {
      const customAttr = isCustomAttribute(
        customAttributes,
        condition.attribute_key
      );
      let inputType = 'plain_text';
      if (customAttr) {
        inputType = getCustomAttributeInputType(customAttr.type);
      } else {
        inputType = getStandardAttributeInputType(
          automationTypes,
          automation.event_name,
          condition.attribute_key
        );
      }
      if (inputType === 'plain_text' || inputType === 'date') {
        return { ...condition, values: condition.values[0] };
      }
      if (inputType === 'comma_separated_plain_text') {
        return { ...condition, values: condition.values.join(',') };
      }
      return {
        ...condition,
        query_operator: condition.query_operator || 'and',
        values: [...getConditionDropdownValues(condition.attribute_key)].filter(
          item => [...condition.values].includes(item.id)
        ),
      };
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

  /**
   * Generates an array of actions for the automation.
   * @param {Object} action - The action object.
   * @param {Array} automationActionTypes - List of available automation action types.
   * @returns {Array|Object} Generated actions array or object based on input type.
   */
  const generateActionsArray = (action, automationActionTypes) => {
    const params = action.action_params;
    const inputType = automationActionTypes.find(
      item => item.key === action.action_name
    ).inputType;
    if (inputType === 'multi_select' || inputType === 'search_select') {
      return [...getActionDropdownValues(action.action_name)].filter(item =>
        [...params].includes(item.id)
      );
    }
    if (inputType === 'team_message') {
      return {
        team_ids: [...getActionDropdownValues(action.action_name)].filter(
          item => [...params[0].team_ids].includes(item.id)
        ),
        message: params[0].message,
      };
    }
    return [...params];
  };

  /**
   * This function sets the actions for automation.
   * It help to format the actions for the automation when we open the edit automation modal.
   * @param {Object} automation - The automation object containing actions.
   * @param {Array} automationActionTypes - List of available automation action types.
   * @returns {Array} An array of manifested actions.
   */
  const manifestActions = (automation, automationActionTypes) => {
    return automation.actions.map(action => ({
      ...action,
      action_params: action.action_params.length
        ? generateActionsArray(action, automationActionTypes)
        : [],
    }));
  };

  /**
   * Formats the automation object for use when we edit the automation.
   * It help to format the conditions and actions for the automation when we open the edit automation modal.
   * @param {Object} automation - The automation object to format.
   * @param {Array} allCustomAttributes - List of all custom attributes.
   * @param {Object} automationTypes - Object containing automation type definitions.
   * @param {Array} automationActionTypes - List of available automation action types.
   * @returns {Object} A new object with formatted automation data, including automation conditions and actions.
   */
  const formatAutomation = (
    automation,
    allCustomAttributes,
    automationTypes,
    automationActionTypes
  ) => {
    return {
      ...automation,
      conditions: manifestConditions(
        automation,
        allCustomAttributes,
        automationTypes
      ),
      actions: manifestActions(automation, automationActionTypes),
    };
  };

  /**
   * This function formats the custom attributes for automation types.
   * It retrieves custom attributes for conversations and contacts,
   * generates custom attribute types, and adds them to the relevant automation types.
   * @param {Object} automationTypes - The automation types object to update with custom attributes.
   */
  const manifestCustomAttributes = automationTypes => {
    const conversationCustomAttributesRaw = getters[
      'attributes/getAttributesByModel'
    ].value('conversation_attribute');
    const contactCustomAttributesRaw =
      getters['attributes/getAttributesByModel'].value('contact_attribute');

    const conversationCustomAttributeTypes = generateCustomAttributeTypes(
      conversationCustomAttributesRaw,
      'conversation_attribute'
    );
    const contactCustomAttributeTypes = generateCustomAttributeTypes(
      contactCustomAttributesRaw,
      'contact_attribute'
    );

    const manifestedCustomAttributes = generateCustomAttributes(
      conversationCustomAttributeTypes,
      contactCustomAttributeTypes,
      t('AUTOMATION.CONDITION.CONVERSATION_CUSTOM_ATTR_LABEL'),
      t('AUTOMATION.CONDITION.CONTACT_CUSTOM_ATTR_LABEL')
    );

    automationTypes.message_created.conditions.push(
      ...manifestedCustomAttributes
    );
    automationTypes.conversation_created.conditions.push(
      ...manifestedCustomAttributes
    );
    automationTypes.conversation_updated.conditions.push(
      ...manifestedCustomAttributes
    );
    automationTypes.conversation_opened.conditions.push(
      ...manifestedCustomAttributes
    );
  };

  return {
    agents,
    campaigns,
    contacts,
    inboxes,
    labels,
    teams,
    slaPolicies,
    booleanFilterOptions,
    statusFilterOptions,
    onEventChange,
    getConditionDropdownValues,
    appendNewCondition,
    appendNewAction,
    removeFilter,
    removeAction,
    resetFilter,
    resetAction,
    formatAutomation,
    getActionDropdownValues,
    manifestCustomAttributes,
  };
}
