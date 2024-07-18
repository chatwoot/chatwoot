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
