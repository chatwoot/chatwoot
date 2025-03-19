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
 * The filter evaluation respects SQL-like operator precedence:
 * https://www.postgresql.org/docs/17/sql-syntax-lexical.html#SQL-PRECEDENCE
 * 1. First evaluates individual conditions
 * 2. Then applies AND operators
 * 3. Finally applies OR operators
 *
 * This means that a filter chain like "A AND B OR C" is evaluated as "(A AND B) OR C",
 * and "A OR B AND C" is evaluated as "A OR (B AND C)".
 *
 * Conversation Object Structure:
 * -----------------------------
 * The conversation object can have:
 * 1. Top-level properties (status, priority, display_id, etc.)
 * 2. Nested properties in additional_attributes (browser_language, referer, etc.)
 * 3. Nested properties in custom_attributes (conversation_type, etc.)
 */

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
 * Checks if a value matches a filter condition
 * @param {*} value - The value to check
 * @param {Object} filter - The filter condition
 * @returns {Boolean} - Returns true if the value matches the filter
 */
const matchesCondition = (value, filter) => {
  const { filterOperator, values } = filter;

  // Handle null/undefined values
  if (value === null || value === undefined) {
    return filterOperator === 'is_not_present';
  }

  switch (filterOperator) {
    case 'equal_to':
      if (Array.isArray(value)) {
        // For array values like labels, check if any of the filter values exist in the array
        return values.some(val => value.includes(val));
      }
      return values.includes(value);

    case 'not_equal_to':
      if (Array.isArray(value)) {
        return !values.some(val => value.includes(val));
      }
      return !values.includes(value);

    case 'contains':
      if (typeof value === 'string') {
        return values.some(val =>
          value.toLowerCase().includes(val.toLowerCase())
        );
      }
      return false;

    case 'does_not_contain':
      if (typeof value === 'string') {
        return !values.some(val =>
          value.toLowerCase().includes(val.toLowerCase())
        );
      }
      return true;

    case 'is_present':
      return true; // We already handled null/undefined above

    case 'is_not_present':
      return false; // We already handled null/undefined above

    case 'is_greater_than':
      return value > values[0];

    case 'is_less_than':
      return value < values[0];

    case 'days_before': {
      const today = new Date();
      const daysInMilliseconds = values[0] * 24 * 60 * 60 * 1000;
      const targetDate = new Date(today.getTime() - daysInMilliseconds);
      return value < targetDate.getTime();
    }

    default:
      return false;
  }
};

/**
 * Checks if a conversation matches the given filters
 * @param {Object} conversation - The conversation object to check
 * @param {Array} filters - Array of filter conditions
 * @returns {Boolean} - Returns true if conversation matches filters, false otherwise
 *
 * This function implements a SQL-like evaluation of filter chains:
 * 1. Each filter is evaluated individually
 * 2. Filters are grouped based on their operators (AND/OR)
 * 3. AND operators take precedence over OR operators
 * 4. The final result respects the proper operator precedence
 *
 * Example filter chains and their evaluation:
 * - "A AND B AND C": All conditions must be true
 * - "A OR B OR C": At least one condition must be true
 * - "A AND B OR C": (A AND B) OR C - Either both A and B are true, or C is true
 * - "A OR B AND C": A OR (B AND C) - Either A is true, or both B and C are true
 * - "A AND (B OR C) AND D": A must be true, either B or C must be true, and D must be true
 */
export const matchesFilters = (conversation, filters) => {
  // If no filters, return true
  if (!filters || filters.length === 0) {
    return true;
  }

  /**
   * IMPORTANT: Backend-Frontend Filter Processing Alignment
   *
   * The backend (FilterService in app/services/filter_service.rb) builds SQL queries by
   * concatenating conditions with the appropriate operators. In the backend:
   *
   * 1. Each filter specifies its own queryOperator (AND/OR) which determines how it
   *    connects to the NEXT filter in the chain.
   *
   * 2. The query_builder method in filter_service.rb iterates through each filter and
   *    appends it to the query string with its specified operator.
   *
   * 3. SQL evaluates expressions from left to right, but respects operator precedence:
   *    - First evaluates individual conditions
   *    - Then applies AND operators
   *    - Finally applies OR operators
   *
   * To maintain alignment with the backend, this frontend implementation:
   *
   * 1. Evaluates each condition individually
   * 2. Processes the conditions in the same order as the backend would
   * 3. Respects operator precedence as SQL would
   *
   * This ensures consistent filtering behavior between frontend and backend.
   */

  // First, evaluate all conditions and collect their results and operators
  const evaluatedFilters = filters.map((filter, index) => {
    const value = getValueFromConversation(conversation, filter.attributeKey);
    const result = matchesCondition(value, filter);
    // The operator is used to connect to the next filter (if any)
    const operator =
      index < filters.length - 1 ? filter.queryOperator || 'and' : null;

    return {
      result,
      operator,
    };
  });

  // If we only have one filter, return its result
  if (evaluatedFilters.length === 1) {
    return evaluatedFilters[0].result;
  }

  // Process the filters in a way that respects SQL's operator precedence
  // We'll use a recursive approach to handle nested expressions

  // First, identify all the OR boundaries
  const orIndices = [];
  for (let i = 0; i < evaluatedFilters.length - 1; i += 1) {
    if (evaluatedFilters[i].operator === 'or') {
      orIndices.push(i);
    }
  }

  // If there are no OR operators, it's a simple AND chain
  if (orIndices.length === 0) {
    return evaluatedFilters.every(filter => filter.result);
  }

  // Split the filters into segments based on OR operators
  const segments = [];
  let startIndex = 0;

  orIndices.forEach(orIndex => {
    segments.push(evaluatedFilters.slice(startIndex, orIndex + 1));
    startIndex = orIndex + 1;
  });

  // Add the last segment if there is one
  if (startIndex < evaluatedFilters.length) {
    segments.push(evaluatedFilters.slice(startIndex));
  }

  // Evaluate each segment (AND conditions within each segment)
  const segmentResults = segments.map(segment => {
    // For segments ending with OR, we only care about the result of the conditions
    if (segment[segment.length - 1].operator === 'or') {
      return segment.every(item => item.result);
    }
    // For the last segment, we evaluate all conditions
    return segment.every(item => item.result);
  });

  // Combine segment results with OR logic
  return segmentResults.some(result => result);
};
