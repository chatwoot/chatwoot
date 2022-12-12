export const MAX_TYPE_SUMMARY_LENGTH = 90;
export const MAX_DEFAULT_VALUE_SUMMARY_LENGTH = 50;
export function isTooLongForTypeSummary(value) {
  return value.length > MAX_TYPE_SUMMARY_LENGTH;
}
export function isTooLongForDefaultValueSummary(value) {
  return value.length > MAX_DEFAULT_VALUE_SUMMARY_LENGTH;
}
export function createSummaryValue(summary, detail) {
  if (summary === detail) {
    return {
      summary
    };
  }

  return {
    summary,
    detail
  };
}
export const normalizeNewlines = string => string.replace(/\\r\\n/g, '\\n');