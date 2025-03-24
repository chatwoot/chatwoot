/**
 * Conversation Filter Helpers
 * ---------------------------
 * This file contains helper functions for filtering conversations in the frontend.
 * The filtering logic is designed to align with the backend SQL behavior to ensure
 * consistent results across the application.
 *
 * Key components:
 * 1. getValueFromConversation: Retrieves values from conversation objects, handling
 *    both top-level properties and nested attributes.
 * 2. matchesCondition: Evaluates a single filter condition against a value.
 * 3. matchesFilters: Evaluates a complete filter chain against a conversation.
 * 4. buildJsonLogicRule: Transforms evaluated filters into a JSON Logic frule that
 *    respects SQL-like operator precedence.
 *
 * Filter Structure:
 * -----------------
 * Each filter has the following structure:
 * {
 *   attributeKey: 'status',          // The attribute to filter on
 *   filterOperator: 'equal_to',      // The operator to use (equal_to, contains, etc.)
 *   values: ['open'],                // The values to compare against
 *   queryOperator: 'and'             // How this filter connects to the next one (and/or)
 * }
 *
 * Operator Precedence:
 * --------------------
 * The filter evaluation respects SQL-like operator precedence using JSON Logic:
 * https://www.postgresql.org/docs/17/sql-syntax-lexical.html#SQL-PRECEDENCE
 * 1. First evaluates individual conditions
 * 2. Then applies AND operators (groups consecutive AND conditions)
 * 3. Finally applies OR operators (connects AND groups with OR operations)
 *
 * This means that a filter chain like "A AND B OR C" is evaluated as "(A AND B) OR C",
 * and "A OR B AND C" is evaluated as "A OR (B AND C)".
 *
 * The implementation uses json-logic-js to apply these rules. The JsonLogic format is designed
 * to allow you to share rules (logic) between front-end and back-end code
 * Here we use json-logic-js to transform filter conditions into a nested JSON Logic structure that preserves proper
 * operator precedence, effectively mimicking SQL-like operator precedence.
 *
 * Conversation Object Structure:
 * -----------------------------
 * The conversation object can have:
 * 1. Top-level properties (status, priority, display_id, etc.)
 * 2. Nested properties in additional_attributes (browser_language, referer, etc.)
 * 3. Nested properties in custom_attributes (conversation_type, etc.)
 */
import jsonLogic from 'json-logic-js';

/**
 * Gets a value from a conversation based on the attribute key
 * @param {Object} conversation - The conversation object
 * @param {String} attributeKey - The attribute key to get the value for
 * @returns {*} - The value of the attribute
 *
 * This function handles various attribute locations:
 * 1. Direct properties on the conversation object (status, priority, etc.)
 * 2. Properties in conversation.additional_attributes (browser_language, referer, etc.)
 * 3. Properties in conversation.custom_attributes (conversation_type, etc.)
 */
const getValueFromConversation = (conversation, attributeKey) => {
  switch (attributeKey) {
    case 'status':
    case 'priority':
    case 'display_id':
    case 'labels':
    case 'created_at':
    case 'last_activity_at':
      return conversation[attributeKey];
    case 'assignee_id':
      return conversation.meta?.assignee?.id;
    case 'inbox_id':
      return conversation.inbox_id;
    case 'team_id':
      return conversation.meta?.team?.id;
    case 'browser_language':
    case 'country_code':
    case 'referer':
      return conversation.additional_attributes?.[attributeKey];
    default:
      // Check if it's a custom attribute
      if (
        conversation.custom_attributes &&
        conversation.custom_attributes[attributeKey]
      ) {
        return conversation.custom_attributes[attributeKey];
      }
      return null;
  }
};

/**
 * Resolves the value from an input candidate
 * @param {*} candidate - The input value to resolve
 * @returns {*} - If the candidate is an object with an id property, returns the id;
 *                otherwise returns the candidate unchanged
 *
 * This helper function is used to normalize values, particularly when dealing with
 * objects that represent entities like users, teams, or inboxes where we want to
 * compare by ID rather than by the whole object.
 */
const resolveValue = candidate => {
  if (
    typeof candidate === 'object' &&
    candidate !== null &&
    'id' in candidate
  ) {
    return candidate.id;
  }

  return candidate;
};

/**
 * Checks if two values are equal in the context of filtering
 * @param {*} filterValue - The filterValue value
 * @param {*} conversationValue - The conversationValue value
 * @returns {Boolean} - Returns true if the values are considered equal according to filtering rules
 *
 * This function handles various equality scenarios:
 * 1. When both values are arrays: checks if all items in filterValue exist in conversationValue
 * 2. When filterValue is an array but conversationValue is not: checks if conversationValue is included in filterValue
 * 3. Otherwise: performs strict equality comparison
 */
const equalTo = (filterValue, conversationValue) => {
  if (Array.isArray(filterValue)) {
    if (filterValue.includes('all')) return true;
    if (filterValue === 'all') return true;

    if (Array.isArray(conversationValue)) {
      // For array values like labels, check if any of the filter values exist in the array
      return filterValue.every(val => conversationValue.includes(val));
    }

    if (!Array.isArray(conversationValue)) {
      return filterValue.includes(conversationValue);
    }
  }

  return conversationValue === filterValue;
};

/**
 * Checks if the filterValue value is contained within the conversationValue value
 * @param {*} filterValue - The value to look for
 * @param {*} conversationValue - The value to search within
 * @returns {Boolean} - Returns true if filterValue is contained within conversationValue
 *
 * This function performs case-insensitive string containment checks.
 * It only works with string values and returns false for non-string types.
 */
const contains = (filterValue, conversationValue) => {
  if (typeof conversationValue === 'string') {
    return conversationValue.toLowerCase().includes(filterValue.toLowerCase());
  }
  return false;
};

/**
 * Checks if a value matches a filter condition
 * @param {*} conversationValue - The value to check
 * @param {Object} filter - The filter condition
 * @returns {Boolean} - Returns true if the value matches the filter
 */
const matchesCondition = (conversationValue, filter) => {
  const { filter_operator: filterOperator, values } = filter;

  // Handle null/undefined values
  if (conversationValue === null || conversationValue === undefined) {
    return filterOperator === 'is_not_present';
  }

  const filterValue = Array.isArray(values)
    ? values.map(resolveValue)
    : resolveValue(values);

  switch (filterOperator) {
    case 'equal_to':
      return equalTo(filterValue, conversationValue);

    case 'not_equal_to':
      return !equalTo(filterValue, conversationValue);

    case 'contains':
      return contains(filterValue, conversationValue);

    case 'does_not_contain':
      return !contains(filterValue, conversationValue);

    case 'is_present':
      return true; // We already handled null/undefined above

    case 'is_not_present':
      return false; // We already handled null/undefined above

    case 'is_greater_than':
      return new Date(conversationValue) > new Date(filterValue);

    case 'is_less_than':
      return new Date(conversationValue) < new Date(filterValue);

    case 'days_before': {
      const today = new Date();
      const daysInMilliseconds = filterValue * 24 * 60 * 60 * 1000;
      const targetDate = new Date(today.getTime() - daysInMilliseconds);
      return conversationValue < targetDate.getTime();
    }

    default:
      return false;
  }
};

/**
 * Converts an array of evaluated filters into a JSON Logic rule
 * that respects SQL-like operator precedence (AND before OR)
 *
 * This function transforms the linear sequence of filter results and operators
 * into a nested JSON Logic structure that correctly implements SQL-like precedence:
 * - AND operators are evaluated before OR operators
 * - Consecutive AND conditions are grouped together
 * - These AND groups are then connected with OR operators
 *
 * For example:
 * - "A AND B AND C" becomes { "and": [A, B, C] }
 * - "A OR B OR C" becomes { "or": [A, B, C] }
 * - "A AND B OR C" becomes { "or": [{ "and": [A, B] }, C] }
 * - "A OR B AND C" becomes { "or": [A, { "and": [B, C] }] }
 *
 * FILTER CHAIN:  A --AND--> B --OR--> C --AND--> D --AND--> E --OR--> F
 *                |         |         |         |         |         |
 *                v         v         v         v         v         v
 * EVALUATED:    true      false     true      false     true      false
 *                \         /         \         \         /         /
 *                 \       /           \         \       /         /
 *                  \     /             \         \     /         /
 *                   \   /               \         \   /         /
 *                    \ /                 \         \ /         /
 * AND GROUPS:      [true,false]          [true,false,true]    [false]
 *                     |                       |                  |
 *                     v                       v                  v
 * JSON LOGIC:    {"and":[true,false]}   {"and":[true,false,true]}  false
 *                   \                      |                  /
 *                    \                     |                 /
 *                     \                    |                /
 *                      \                   |               /
 *                       \                  |              /
 * FINAL RULE:            {"or":[{"and":[true,false]},{"and":[true,false,true]},false]}
 *
 * {
 *  "or": [
 *    { "and": [true, false] },
 *    { "and": [true, false, true] },
 *    { "and": [false] }
 *  ]
 * }
 * @param {Array} evaluatedFilters - Array of evaluated filter conditions with results and operators
 * @returns {Object} - JSON Logic rule
 */
const buildJsonLogicRule = evaluatedFilters => {
  // Step 1: Group consecutive AND conditions into logical units
  // This implements the higher precedence of AND over OR
  const andGroups = [];
  let currentAndGroup = [evaluatedFilters[0].result];

  for (let i = 0; i < evaluatedFilters.length - 1; i += 1) {
    if (evaluatedFilters[i].operator === 'and') {
      // When we see an AND operator, we add the next filter to the current AND group
      // This builds up chains of AND conditions that will be evaluated together
      currentAndGroup.push(evaluatedFilters[i + 1].result);
    } else {
      // When we see an OR operator, it marks the boundary between AND groups
      // We finalize the current AND group and start a new one

      // If the AND group has only one item, don't wrap it in an "and" operator
      // Otherwise, create a proper "and" JSON Logic expression
      andGroups.push(
        currentAndGroup.length === 1
          ? currentAndGroup[0] // Single item doesn't need an "and" wrapper
          : { and: currentAndGroup } // Multiple items need to be AND-ed together
      );

      // Start a new AND group with the next filter's result
      currentAndGroup = [evaluatedFilters[i + 1].result];
    }
  }

  // Step 2: Add the final AND group that wasn't followed by an OR
  if (currentAndGroup.length > 0) {
    andGroups.push(
      currentAndGroup.length === 1
        ? currentAndGroup[0] // Single item doesn't need an "and" wrapper
        : { and: currentAndGroup } // Multiple items need to be AND-ed together
    );
  }

  // Step 3: Combine all AND groups with OR operators
  // If we have multiple AND groups, they are separated by OR operators
  // in the original filter chain, so we combine them with an "or" operation
  if (andGroups.length > 1) {
    return { or: andGroups };
  }

  // If there's only one AND group (which might be a single condition
  // or multiple AND-ed conditions), just return it directly
  return andGroups[0];
};

/**
 * Evaluates each filter against the conversation and prepares the results array
 * @param {Object} conversation - The conversation to evaluate
 * @param {Array} filters - Filters to apply
 * @returns {Array} - Array of evaluated filter results with operators
 */
const evaluateFilters = (conversation, filters) => {
  return filters.map((filter, index) => {
    const value = getValueFromConversation(conversation, filter.attribute_key);
    const result = matchesCondition(value, filter);

    // This part determines the logical operator that connects this filter to the next one:
    // - If this is not the last filter (index < filters.length - 1), use the filter's query_operator
    //   or default to 'and' if query_operator is not specified
    // - If this is the last filter, set operator to null since there's no next filter to connect to
    const isLastFilter = index === filters.length - 1;
    const operator = isLastFilter ? null : filter.query_operator || 'and';

    return { result, operator };
  });
};

/**
 * Checks if a conversation matches the given filters
 * @param {Object} conversation - The conversation object to check
 * @param {Array} filters - Array of filter conditions
 * @returns {Boolean} - Returns true if conversation matches filters, false otherwise
 */
export const matchesFilters = (conversation, filters) => {
  // If no filters, return true
  if (!filters || filters.length === 0) {
    return true;
  }

  // Handle single filter case
  if (filters.length === 1) {
    const value = getValueFromConversation(
      conversation,
      filters[0].attribute_key
    );
    return matchesCondition(value, filters[0]);
  }

  // Evaluate all conditions and prepare for jsonLogic
  const evaluatedFilters = evaluateFilters(conversation, filters);
  return jsonLogic.apply(buildJsonLogicRule(evaluatedFilters));
};
