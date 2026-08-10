// jsonb-backed flags (bot_config, additional_attributes) round-trip through multipart
// form submissions as the literal strings "true"/"false" rather than real booleans,
// so a plain `value || false` treats a saved-off "false" as truthy. Normalize explicitly.
export const isTruthyFlag = value => value === true || value === 'true';
