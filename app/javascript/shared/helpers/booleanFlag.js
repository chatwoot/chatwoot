// jsonb-backed flags (bot_config, additional_attributes) can be saved as non-boolean
// values: multipart form submissions send the literal strings "true"/"false", and the
// public API accepts anything ActiveModel::Type::Boolean casts (e.g. 1, "t", "off").
// Mirror that casting here so the UI never disagrees with what the backend will do.
const FALSE_VALUES = new Set([
  false,
  0,
  '0',
  'f',
  'F',
  'false',
  'FALSE',
  'off',
  'OFF',
]);

export const isTruthyFlag = value => {
  if (value === null || value === undefined || value === '') return false;
  return !FALSE_VALUES.has(value);
};
