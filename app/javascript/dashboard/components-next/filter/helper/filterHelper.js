/**
 * Standard attributes of the conversation model
 */
export const CONVERSATION_ATTRIBUTES = {
  STATUS: 'status',
  PRIORITY: 'priority',
  ASSIGNEE_ID: 'assignee_id',
  INBOX_ID: 'inbox_id',
  TEAM_ID: 'team_id',
  DISPLAY_ID: 'display_id',
  CAMPAIGN_ID: 'campaign_id',
  LABELS: 'labels',
  BROWSER_LANGUAGE: 'browser_language',
  COUNTRY_CODE: 'country_code',
  REFERER: 'referer',
  CREATED_AT: 'created_at',
  LAST_ACTIVITY_AT: 'last_activity_at',
};

export const CONTACT_ATTRIBUTES = {
  NAME: 'name',
  EMAIL: 'email',
  PHONE_NUMBER: 'phone_number',
  IDENTIFIER: 'identifier',
  COUNTRY_CODE: 'country_code',
  CITY: 'city',
  CREATED_AT: 'created_at',
  LAST_ACTIVITY_AT: 'last_activity_at',
  REFERER: 'referer',
  BLOCKED: 'blocked',
};

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
 * This also removes any conflicting attributes
 * @param {Array} attributes - The attributes array
 * @param {Function} getOperatorTypes - Function to get operator types
 * @returns {Array} Array of filter types
 */
export const buildAttributesFilterTypes = (
  attributes,
  getOperatorTypes,
  filterModel = 'conversation'
) => {
  const standardAttributes = Object.values(
    filterModel === 'conversation'
      ? CONVERSATION_ATTRIBUTES
      : CONTACT_ATTRIBUTES
  );

  return attributes
    .filter(attr => !standardAttributes.includes(attr.attributeKey))
    .map(attr => ({
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

/**
 * Replaces underscores with spaces in a string
 * @param {string} text - The input string
 * @returns {string} The string with underscores replaced by spaces
 */
export const replaceUnderscoreWithSpace = text =>
  text?.replaceAll('_', ' ') ?? '';
