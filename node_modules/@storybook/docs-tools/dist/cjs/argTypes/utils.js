"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MAX_TYPE_SUMMARY_LENGTH = exports.MAX_DEFAULT_VALUE_SUMMARY_LENGTH = void 0;
exports.createSummaryValue = createSummaryValue;
exports.isTooLongForDefaultValueSummary = isTooLongForDefaultValueSummary;
exports.isTooLongForTypeSummary = isTooLongForTypeSummary;
exports.normalizeNewlines = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

var MAX_TYPE_SUMMARY_LENGTH = 90;
exports.MAX_TYPE_SUMMARY_LENGTH = MAX_TYPE_SUMMARY_LENGTH;
var MAX_DEFAULT_VALUE_SUMMARY_LENGTH = 50;
exports.MAX_DEFAULT_VALUE_SUMMARY_LENGTH = MAX_DEFAULT_VALUE_SUMMARY_LENGTH;

function isTooLongForTypeSummary(value) {
  return value.length > MAX_TYPE_SUMMARY_LENGTH;
}

function isTooLongForDefaultValueSummary(value) {
  return value.length > MAX_DEFAULT_VALUE_SUMMARY_LENGTH;
}

function createSummaryValue(summary, detail) {
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

var normalizeNewlines = function normalizeNewlines(string) {
  return string.replace(/\\r\\n/g, '\\n');
};

exports.normalizeNewlines = normalizeNewlines;