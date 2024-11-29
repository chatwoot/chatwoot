/**
 * Determines the input type for a custom attribute based on its key
 * @param {string} key - The attribute display type key
 * @returns {'date'|'plainText'|'searchSelect'|'booleanSelect'} The corresponding input type
 */
export const getCustomAttributeInputType = key => {
  switch (key) {
    case 'date':
      return 'date';
    case 'text':
      return 'plainText';
    case 'list':
      return 'searchSelect';
    case 'checkbox':
      return 'booleanSelect';
    default:
      return 'plainText';
  }
};

/**
 * Builds filter types for custom attributes
 * @param {Array} attributes - The attributes array
 * @param {Function} getOperatorTypes - Function to get operator types
 * @returns {Array} Array of filter types
 */
export const buildAttributesFilterTypes = (attributes, getOperatorTypes) => {
  return attributes.map(attr => ({
    attributeKey: attr.attributeKey,
    value: attr.attributeKey,
    attributeName: attr.attributeDisplayName,
    label: attr.attributeDisplayName,
    inputType: getCustomAttributeInputType(attr.attributeDisplayType),
    filterOperators: getOperatorTypes(attr.attributeDisplayType),
    options:
      attr.attributeDisplayType === 'list'
        ? attr.attributeValues.map(item => ({ id: item, name: item }))
        : [],
    attributeModel: 'customAttributes',
  }));
};
