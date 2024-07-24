// ------------------------------------------------------------------
// ------------------------ Filter Validation -----------------------
// ------------------------------------------------------------------

/**
 * Validates a single filter for conversations or contacts.
 *
 * @param {Object} filter - The filter object to validate.
 * @param {string} filter.attribute_key - The key of the attribute to filter on.
 * @param {string} filter.filter_operator - The operator to use for filtering.
 * @param {string|number} [filter.values] - The value(s) to filter by (required for most operators).
 *
 * @returns {string|null} An error message if validation fails, or null if validation passes.
 */
const validateSingleFilter = filter => {
  if (!filter.attribute_key) {
    return 'Attribute key is required';
  }

  if (!filter.filter_operator) {
    return 'Filter operator is required';
  }

  if (
    filter.filter_operator !== 'is_present' &&
    filter.filter_operator !== 'is_not_present' &&
    !filter.values
  ) {
    return 'Value is required';
  }

  if (
    filter.filter_operator === 'days_before' &&
    (parseInt(filter.values, 10) <= 0 || parseInt(filter.values, 10) >= 999)
  ) {
    return 'Value must be between 1 and 998';
  }

  return null;
};

/**
 * Validates filters for conversations or contacts.
 *
 * @param {Array} filters - An array of filter objects to validate.
 * @param {string} filters[].attribute_key - The key of the attribute to filter on.
 * @param {string} filters[].filter_operator - The operator to use for filtering.
 * @param {string|number} [filters[].values] - The value(s) to filter by (required for most operators).
 *
 * @returns {Object} An object containing any validation errors, keyed by filter index.
 */
export const validateConversationOrContactFilters = filters => {
  const errors = {};

  filters.forEach((filter, index) => {
    const error = validateSingleFilter(filter);
    if (error) {
      errors[`filter_${index}`] = error;
    }
  });

  return errors;
};

// ------------------------------------------------------------------
// ---------------------- Automation Validation ---------------------
// ------------------------------------------------------------------

/**
 * Validates the basic fields of an automation object.
 *
 * @param {Object} automation - The automation object to validate.
 * @returns {Object} An object containing any validation errors.
 */
const validateBasicFields = automation => {
  const errors = {};
  const requiredFields = ['name', 'description', 'event_name'];

  requiredFields.forEach(field => {
    if (!automation[field]) {
      errors[field] = `${
        field.charAt(0).toUpperCase() + field.slice(1)
      } is required`;
    }
  });

  return errors;
};

/**
 * Validates the conditions of an automation object.
 *
 * @param {Array} conditions - The conditions to validate.
 * @returns {Object} An object containing any validation errors.
 */
export const validateConditions = conditions => {
  const errors = {};

  if (!conditions || conditions.length === 0) {
    errors.conditions = 'At least one condition is required';
    return errors;
  }

  conditions.forEach((condition, index) => {
    const error = validateSingleFilter(condition);
    if (error) {
      errors[`condition_${index}`] = error;
    }
  });

  return errors;
};

/**
 * Validates a single action of an automation object.
 *
 * @param {Object} action - The action to validate.
 * @returns {string|null} An error message if validation fails, or null if validation passes.
 */
const validateSingleAction = action => {
  const noParamActions = [
    'mute_conversation',
    'snooze_conversation',
    'resolve_conversation',
  ];

  if (
    !noParamActions.includes(action.action_name) &&
    (!action.action_params || action.action_params.length === 0)
  ) {
    return 'Action parameters are required';
  }

  return null;
};

/**
 * Validates the actions of an automation object.
 *
 * @param {Array} actions - The actions to validate.
 * @returns {Object} An object containing any validation errors.
 */
export const validateActions = actions => {
  if (!actions || actions.length === 0) {
    return { actions: 'At least one action is required' };
  }

  return actions.reduce((errors, action, index) => {
    const error = validateSingleAction(action);
    if (error) {
      errors[`action_${index}`] = error;
    }
    return errors;
  }, {});
};

/**
 * Validates an automation object.
 *
 * @param {Object} automation - The automation object to validate.
 * @param {string} automation.name - The name of the automation.
 * @param {string} automation.description - The description of the automation.
 * @param {string} automation.event_name - The name of the event that triggers the automation.
 * @param {Array} automation.conditions - An array of condition objects for the automation.
 * @param {string} automation.conditions[].filter_operator - The operator for the condition.
 * @param {string|number} [automation.conditions[].values] - The value(s) for the condition.
 * @param {Array} automation.actions - An array of action objects for the automation.
 * @param {string} automation.actions[].action_name - The name of the action.
 * @param {Array} [automation.actions[].action_params] - The parameters for the action.
 *
 * @returns {Object} An object containing any validation errors.
 */
export const validateAutomation = automation => {
  const basicErrors = validateBasicFields(automation);
  const conditionErrors = validateConditions(automation.conditions);
  const actionErrors = validateActions(automation.actions);

  return {
    ...basicErrors,
    ...conditionErrors,
    ...actionErrors,
  };
};
