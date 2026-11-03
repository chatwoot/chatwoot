import { buildDatePresetConditions } from './datePresets';

/**
 * Number of options a filter dropdown can hold before it renders a search field.
 * Shared so the attribute and value dropdowns never disagree on when to show one.
 */
export const DROPDOWN_SEARCH_THRESHOLD = 8;

/**
 * Length limits for a description sent to build filters. The API rejects anything outside them.
 */
export const DESCRIBE_QUERY_MIN_LENGTH = 3;
export const DESCRIBE_QUERY_MAX_LENGTH = 200;

/**
 * Standard attributes of the conversation model
 */
export const CONVERSATION_ATTRIBUTES = {
  STATUS: 'status',
  PRIORITY: 'priority',
  ASSIGNEE_ID: 'assignee_id',
  INBOX_ID: 'inbox_id',
  TEAM_ID: 'team_id',
  CONTACT_ID: 'contact_id',
  DISPLAY_ID: 'display_id',
  CAMPAIGN_ID: 'campaign_id',
  LABELS: 'labels',
  BROWSER_LANGUAGE: 'browser_language',
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
  COMPANY_NAME: 'company_name',
  CREATED_AT: 'created_at',
  LAST_ACTIVITY_AT: 'last_activity_at',
  REFERER: 'referer',
  BLOCKED: 'blocked',
  LABELS: 'labels',
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
    case 'number':
      return 'number';
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
      attributeDisplayType: attr.attributeDisplayType,
      filterOperators: getOperatorTypes(attr.attributeDisplayType),
      options:
        attr.attributeDisplayType === 'list'
          ? attr.attributeValues.map(item => ({ id: item, name: item }))
          : [],
      attributeModel: 'customAttributes',
    }));
};

const VALUELESS_OPERATORS = ['is_present', 'is_not_present'];

const recommendedValues = (filterType, filterOperator, values) => {
  if (VALUELESS_OPERATORS.includes(filterOperator)) return [];
  if (filterType.inputType === 'multiSelect') {
    return filterType.options.filter(option => values.includes(option.id));
  }
  if (filterType.inputType === 'searchSelect') {
    return filterType.options.find(option => option.id === values[0]) ?? {};
  }
  if (filterType.inputType === 'multiText') return values;
  return values[0]?.toString() ?? '';
};

const recommendedConditions = (recommendation, filterType, today) => {
  if (recommendation.date_preset) {
    return buildDatePresetConditions(
      recommendation.date_preset,
      recommendation.days,
      today
    );
  }

  return [
    {
      filterOperator: recommendation.filter_operator,
      values: recommendedValues(
        filterType,
        recommendation.filter_operator,
        recommendation.values
      ),
    },
  ];
};

const describeValues = values => {
  if (Array.isArray(values)) {
    return values.map(value => value?.name ?? value).join(', ');
  }
  if (values && typeof values === 'object') return values.name ?? '';
  return values ?? '';
};

// A readable summary of a recommendation's rows, such as "Priority Equal to Urgent".
const describeRecommendation = (rows, filterType) =>
  rows
    .map(row => {
      const operatorLabel =
        filterType.filterOperators?.find(
          operator => operator.value === row.filterOperator
        )?.label ?? row.filterOperator;
      return [filterType.label, operatorLabel, describeValues(row.values)]
        .filter(Boolean)
        .join(' ');
    })
    .join(', ');

/**
 * Turns recommended conditions from the API into groups of filter rows, one group per recommendation.
 * A condition on an attribute the form does not offer is dropped.
 * A date condition names a preset, which becomes one or two date rows.
 * @param {Array<{attribute_key: string, filter_operator?: string, values?: Array, date_preset?: string, days?: number}>} recommendations
 * @param {Array} filterTypes - The filter types from the filter context
 * @param {Date} [today] - The reference date for date presets
 * @returns {Array<{attributeKey: string, label: string, icon: any, rows: Array}>}
 */
export const buildRecommendationGroups = (
  recommendations,
  filterTypes,
  today = new Date()
) =>
  recommendations.flatMap(recommendation => {
    const filterType = filterTypes.find(
      type => type.attributeKey === recommendation.attribute_key
    );
    if (!filterType) return [];

    const rows = recommendedConditions(recommendation, filterType, today).map(
      condition => ({
        attributeKey: recommendation.attribute_key,
        attributeModel: filterType.attributeModel,
        queryOperator: 'and',
        ...condition,
      })
    );
    return [
      {
        attributeKey: recommendation.attribute_key,
        label: describeRecommendation(rows, filterType),
        icon: filterType.icon,
        rows,
      },
    ];
  });

/**
 * Turns recommended conditions from the API into filter rows for the filter form.
 * @param {Array} recommendations - Conditions from the filter recommendations API
 * @param {Array} filterTypes - The filter types from the filter context
 * @param {Date} [today] - The reference date for date presets
 * @returns {Array} Filter rows
 */
export const buildFiltersFromRecommendations = (
  recommendations,
  filterTypes,
  today = new Date()
) =>
  buildRecommendationGroups(recommendations, filterTypes, today).flatMap(
    group => group.rows
  );

/**
 * Replaces underscores with spaces in a string
 * @param {string} text - The input string
 * @returns {string} The string with underscores replaced by spaces
 */
export const replaceUnderscoreWithSpace = text =>
  text?.replaceAll('_', ' ') ?? '';
