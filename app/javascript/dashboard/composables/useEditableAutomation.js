import useAutomationValues from './useAutomationValues';

import {
  filterCustomAttributes,
  getCustomAttributeInputType,
  getStandardAttributeInputType,
  isCustomAttribute,
} from 'dashboard/helper/automationHelper';

export function useEditableAutomation() {
  const { getConditionDropdownValues, getActionDropdownValues } =
    useAutomationValues();

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
      const base = {
        ...condition,
        query_operator: condition.query_operator || 'and',
      };

      if (
        inputType === 'plain_text' ||
        inputType === 'date' ||
        inputType === 'datetime'
      ) {
        return { ...base, values: condition.values[0] };
      }
      if (inputType === 'comma_separated_plain_text') {
        return { ...base, values: condition.values.join(',') };
      }
      const dropdownValues = getConditionDropdownValues(
        condition.attribute_key
      );
      const hasBooleanOptions =
        inputType === 'search_select' &&
        dropdownValues.length &&
        dropdownValues.every(item => typeof item.id === 'boolean');

      if (hasBooleanOptions) {
        return {
          ...base,
          values: dropdownValues.find(item => item.id === condition.values[0]),
        };
      }
      return {
        ...base,
        values: [...dropdownValues].filter(item =>
          [...condition.values].includes(item.id)
        ),
      };
    });
  };

  const isCustomAttributeAction = actionName =>
    [
      'update_contact_custom_attribute',
      'update_conversation_custom_attribute',
    ].includes(actionName);

  const emptyCustomAttributeParams = () => ({
    attribute_key: '',
    value: '',
  });

  const hasActionParams = params => {
    if (Array.isArray(params)) return params.length > 0;
    if (params && typeof params === 'object') {
      return Object.keys(params).length > 0;
    }
    return Boolean(params);
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
    )?.inputType;

    if (
      inputType === 'custom_attribute' ||
      isCustomAttributeAction(action.action_name)
    ) {
      const data = Array.isArray(params) ? params[0] || {} : params || {};
      return {
        attribute_key: data.attribute_key || '',
        value: data.value ?? '',
      };
    }
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
    if (inputType === 'whatsapp_template') {
      const data = Array.isArray(params) ? params[0] || {} : params || {};
      return {
        inbox_id: data.inbox_id || null,
        name: data.name || '',
        language: data.language || '',
        namespace: data.namespace || '',
        category: data.category || '',
        processed_params: data.processed_params || {},
      };
    }
    return Array.isArray(params) ? [...params] : [];
  };

  /**
   * This function sets the actions for automation.
   * It help to format the actions for the automation when we open the edit automation modal.
   * @param {Object} automation - The automation object containing actions.
   * @param {Array} automationActionTypes - List of available automation action types.
   * @returns {Array} An array of manifested actions.
   */
  const manifestActions = (automation, automationActionTypes) => {
    return automation.actions.map(action => {
      if (!hasActionParams(action.action_params)) {
        return {
          ...action,
          action_params: isCustomAttributeAction(action.action_name)
            ? emptyCustomAttributeParams()
            : [],
        };
      }

      return {
        ...action,
        action_params: generateActionsArray(action, automationActionTypes),
      };
    });
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

  return { formatAutomation };
}
