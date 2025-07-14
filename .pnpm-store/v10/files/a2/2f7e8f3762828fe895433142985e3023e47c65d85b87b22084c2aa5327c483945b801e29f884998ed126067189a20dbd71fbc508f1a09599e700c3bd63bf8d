import type { Span, SpanAttributes, SpanTimeInput, StartSpanOptions } from '@sentry/types';
/**
 * Checks if a given value is a valid measurement value.
 */
export declare function isMeasurementValue(value: unknown): value is number;
/**
 * Helper function to start child on transactions. This function will make sure that the transaction will
 * use the start timestamp of the created child span if it is earlier than the transactions actual
 * start timestamp.
 */
export declare function startAndEndSpan(parentSpan: Span, startTimeInSeconds: number, endTime: SpanTimeInput, { ...ctx }: StartSpanOptions): Span | undefined;
interface StandaloneWebVitalSpanOptions {
    name: string;
    transaction?: string;
    attributes: SpanAttributes;
    startTime: number;
}
/**
 * Starts an inactive, standalone span used to send web vital values to Sentry.
 * DO NOT use this for arbitrary spans, as these spans require special handling
 * during ingestion to extract metrics.
 *
 * This function adds a bunch of attributes and data to the span that's shared
 * by all web vital standalone spans. However, you need to take care of adding
 * the actual web vital value as an event to the span. Also, you need to assign
 * a transaction name and some other values that are specific to the web vital.
 *
 * Ultimately, you also need to take care of ending the span to send it off.
 *
 * @param options
 *
 * @returns an inactive, standalone and NOT YET ended span
 */
export declare function startStandaloneWebVitalSpan(options: StandaloneWebVitalSpanOptions): Span | undefined;
/** Get the browser performance API. */
export declare function getBrowserPerformanceAPI(): Performance | undefined;
/**
 * Converts from milliseconds to seconds
 * @param time time in ms
 */
export declare function msToSec(time: number): number;
export {};
//# sourceMappingURL=utils.d.ts.map