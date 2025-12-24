const setArrayValues = item => {
  return item.values[0]?.id ? item.values.map(val => val.id) : item.values;
};

const generateValues = item => {
  if (item.attribute_key === 'content') {
    const values = item.values || '';
    return values
      .trim()
      .split('||')
      .map(value => value.trim());
  }
  if (Array.isArray(item.values)) {
    return setArrayValues(item);
  }
  if (typeof item.values === 'object') {
    return [item.values.id];
  }
  if (!item.values) {
    return [];
  }
  return [item.values];
};

// Helper to convert local datetime to UTC ISO string
const convertToUTC = localDatetimeString => {
  if (!localDatetimeString) return localDatetimeString;

  // Check if it's a datetime-local format (contains 'T')
  if (localDatetimeString.includes('T')) {
    // Parse as local time and convert to UTC ISO string
    const localDate = new Date(localDatetimeString);
    return localDate.toISOString();
  }

  // Legacy support: If it's just a date (YYYY-MM-DD), treat as start of day in local timezone
  if (localDatetimeString.match(/^\d{4}-\d{2}-\d{2}$/)) {
    const localDate = new Date(localDatetimeString + 'T00:00:00');
    return localDate.toISOString();
  }

  return localDatetimeString;
};

const generatePayload = data => {
  // Make a copy of data to avoid vue data reactivity issues
  const filters = JSON.parse(JSON.stringify(data));

  // Get user's browser timezone
  const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  let payload = filters.map(item => {
    // If item key is content, we will split it using comma and return as array
    // FIX ME: Make this generic option instead of using the key directly here
    item.values = generateValues(item);

    // Convert datetime values to UTC for date/time filters
    if (
      item.attribute_key === 'created_at' ||
      item.attribute_key === 'last_activity_at'
    ) {
      // For today_within_hours, pass timezone info (don't convert values)
      if (item.filter_operator === 'today_within_hours') {
        item.timezone = userTimezone;
      } else if (item.values && Array.isArray(item.values)) {
        // For other operators, convert to UTC
        item.values = item.values.map(convertToUTC);
      }
    }

    return item;
  });

  // For every query added, the query_operator is set default to and so the
  // last query will have an extra query_operator, this would break the api.
  // Setting this to null for all query payload
  payload[payload.length - 1].query_operator = undefined;
  return { payload };
};

export default generatePayload;
