import { ref } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import {
  generateCustomAttributeTypes,
  getDefaultConditions,
  getDefaultActions,
  generateCustomAttributes,
} from 'dashboard/helper/automationHelper';
import useAutomationValues from './useAutomationValues';

/**
 * Composable for handling automation-related functionality.
 * @returns {Object} An object containing various automation-related functions and computed properties.
 */
export function useAutomation(startValue = null) {
  const getters = useStoreGetters();
  const { t } = useI18n();

  const {
    booleanFilterOptions,
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
  } = useAutomationValues();

  const automation = ref(startValue);

  /**
   * Handles the event change for an automation.
   * @param {Object} automation - The automation object to update.
   */
  const onEventChange = automation => {
    automation.conditions = getDefaultConditions(automation.event_name);
    automation.actions = getDefaultActions();
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
    automation,
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
    getActionDropdownValues,
    manifestCustomAttributes,
  };
}
