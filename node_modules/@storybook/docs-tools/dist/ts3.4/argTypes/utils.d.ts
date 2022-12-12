import { PropSummaryValue } from './docgen';
export declare const MAX_TYPE_SUMMARY_LENGTH = 90;
export declare const MAX_DEFAULT_VALUE_SUMMARY_LENGTH = 50;
export declare function isTooLongForTypeSummary(value: string): boolean;
export declare function isTooLongForDefaultValueSummary(value: string): boolean;
export declare function createSummaryValue(summary: string, detail?: string): PropSummaryValue;
export declare const normalizeNewlines: (string: string) => string;
