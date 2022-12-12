import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
export var MAX_TYPE_SUMMARY_LENGTH = 90;
export var MAX_DEFAULT_VALUE_SUMMARY_LENGTH = 50;
export function isTooLongForTypeSummary(value) {
  return value.length > MAX_TYPE_SUMMARY_LENGTH;
}
export function isTooLongForDefaultValueSummary(value) {
  return value.length > MAX_DEFAULT_VALUE_SUMMARY_LENGTH;
}
export function createSummaryValue(summary, detail) {
  if (summary === detail) {
    return {
      summary: summary
    };
  }

  return {
    summary: summary,
    detail: detail
  };
}
export var normalizeNewlines = function normalizeNewlines(string) {
  return string.replace(/\\r\\n/g, '\\n');
};