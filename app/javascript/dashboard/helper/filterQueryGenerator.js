const TIMESTAMP_ATTRIBUTES = ['created_at', 'last_activity_at'];

export const withTimestampTimezone = filter => {
  const { timezone, ...attributes } = filter;
  if (!TIMESTAMP_ATTRIBUTES.includes(filter.attribute_key)) return attributes;

  return {
    ...attributes,
    timezone: timezone || Intl.DateTimeFormat().resolvedOptions().timeZone,
  };
};

const setArrayValues = item => {
  return item.values[0]?.id ? item.values.map(val => val.id) : item.values;
};

const generateValues = item => {
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

const generatePayload = (data, { useLocalTimezone = true } = {}) => {
  // Make a copy of data to avoid vue data reactivity issues
  const filters = JSON.parse(JSON.stringify(data));
  let payload = filters.map(item => {
    item.values = generateValues(item);
    return useLocalTimezone ? withTimestampTimezone(item) : item;
  });

  // For every query added, the query_operator is set default to and so the
  // last query will have an extra query_operator, this would break the api.
  // Setting this to null for all query payload
  payload[payload.length - 1].query_operator = undefined;
  return { payload };
};

export default generatePayload;
