const lowerCaseValues = (operator, values) => {
  if (operator === 'equal_to' || operator === 'not_equal_to') {
    values = values.map(val => {
      if (typeof val === 'string') {
        return val.toLowerCase();
      }
      return val;
    });
  }
  return values;
};

const generatePayload = data => {
  // Make a copy of data to avoid vue data reactivity issues
  const filters = JSON.parse(JSON.stringify(data));
  let payload = filters.map(item => {
    if (Array.isArray(item.values)) {
      item.values = item.values.map(val => val.id);
    } else if (typeof item.values === 'object') {
      item.values = [item.values.id];
    } else if (!item.values) {
      item.values = [];
    } else {
      item.values = [item.values];
    }
    // Convert all values to lowerCase if operator_type is 'equal_to' or 'not_equal_to'
    item.values = lowerCaseValues(item.filter_operator, item.values);
    return item;
  });
  // For every query added, the query_operator is set default to and so the
  // last query will have an extra query_operator, this would break the api.
  // Setting this to null for all query payload
  payload[payload.length - 1].query_operator = undefined;
  return { payload };
};

export default generatePayload;
