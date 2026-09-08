export const formatFlowResponseLabel = key =>
  key
    .replace(/([a-z\d])([A-Z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, character => character.toUpperCase());

export const formatFlowResponseValue = value => {
  if (value === null || value === undefined || value === '') return '—';
  if (typeof value === 'object') return JSON.stringify(value, null, 2);

  return String(value);
};

export const buildFlowResponseEntries = response => {
  const entries =
    response && typeof response === 'object' && !Array.isArray(response)
      ? Object.entries(response)
      : [['response', response]];

  return entries
    .filter(([key]) => key !== 'flow_token')
    .map(([key, value]) => ({
      key,
      label: formatFlowResponseLabel(key),
      value: formatFlowResponseValue(value),
    }));
};
