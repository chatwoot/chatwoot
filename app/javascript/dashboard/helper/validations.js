export const validateConversationOrContactFilters = filters => {
  const errors = {};

  filters.forEach((filter, index) => {
    if (!filter.attribute_key) {
      errors[`filter_${index}`] = 'Attribute key is required';
    } else if (!filter.filter_operator) {
      errors[`filter_${index}`] = 'Filter operator is required';
    } else if (
      filter.filter_operator !== 'is_present' &&
      filter.filter_operator !== 'is_not_present' &&
      !filter.values
    ) {
      errors[`filter_${index}`] = 'Value is required';
    } else if (
      filter.filter_operator === 'days_before' &&
      (parseInt(filter.values, 10) <= 0 || parseInt(filter.values, 10) >= 999)
    ) {
      errors[`filter_${index}`] = 'Value must be between 1 and 998';
    }
  });

  return errors;
};

export const validateAutomation = automation => {
  const errors = {};

  if (!automation.name) {
    errors.name = 'Name is required';
  }

  if (!automation.description) {
    errors.description = 'Description is required';
  }

  if (!automation.event_name) {
    errors.event_name = 'Event name is required';
  }

  if (!automation.conditions || automation.conditions.length === 0) {
    errors.conditions = 'At least one condition is required';
  } else {
    automation.conditions.forEach((condition, index) => {
      if (
        !(
          condition.filter_operator === 'is_present' ||
          condition.filter_operator === 'is_not_present'
        ) &&
        !condition.values
      ) {
        errors[`condition_${index}`] = 'Value is required';
      }
    });
  }

  if (!automation.actions || automation.actions.length === 0) {
    errors.actions = 'At least one action is required';
  } else {
    automation.actions.forEach((action, index) => {
      if (
        !(
          action.action_name === 'mute_conversation' ||
          action.action_name === 'snooze_conversation' ||
          action.action_name === 'resolve_conversation'
        ) &&
        (!action.action_params || action.action_params.length === 0)
      ) {
        errors[`action_${index}`] = 'Action parameters are required';
      }
    });
  }

  return errors;
};
