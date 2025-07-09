import { MeasurementUnit, Primitive, Span, SpanAttributes, SpanJSON, SpanStatus, SpanTimeInput, TraceContext } from '@sentry/types';
import { MetricType } from '../metrics/types';
export declare const TRACE_FLAG_NONE = 0;
export declare const TRACE_FLAG_SAMPLED = 1;
/**
 * Convert a span to a trace context, which can be sent as the `trace` context in an event.
 * By default, this will only include trace_id, span_id & parent_span_id.
 * If `includeAllData` is true, it will also include data, op, status & origin.
 */
export declare function spanToTransactionTraceContext(span: Span): TraceContext;
/**
 * Convert a span to a trace context, which can be sent as the `trace` context in a non-transaction event.
 */
export declare function spanToTraceContext(span: Span): TraceContext;
/**
 * Convert a Span to a Sentry trace header.
 */
export declare function spanToTraceHeader(span: Span): string;
/**
 * Convert a span time input into a timestamp in seconds.
 */
export declare function spanTimeInputToSeconds(input: SpanTimeInput | undefined): number;
/**
 * Convert a span to a JSON representation.
 */
export declare function spanToJSON(span: Span): Partial<SpanJSON>;
/** Exported only for tests. */
export interface OpenTelemetrySdkTraceBaseSpan extends Span {
    attributes: SpanAttributes;
    startTime: SpanTimeInput;
    name: string;
    status: SpanStatus;
    endTime: SpanTimeInput;
    parentSpanId?: string;
}
/**
 * Returns true if a span is sampled.
 * In most cases, you should just use `span.isRecording()` instead.
 * However, this has a slightly different semantic, as it also returns false if the span is finished.
 * So in the case where this distinction is important, use this method.
 */
export declare function spanIsSampled(span: Span): boolean;
/** Get the status message to use for a JSON representation of a span. */
export declare function getStatusMessage(status: SpanStatus | undefined): string | undefined;
declare const CHILD_SPANS_FIELD = "_sentryChildSpans";
declare const ROOT_SPAN_FIELD = "_sentryRootSpan";
type SpanWithPotentialChildren = Span & {
    [CHILD_SPANS_FIELD]?: Set<Span>;
    [ROOT_SPAN_FIELD]?: Span;
};
/**
 * Adds an opaque child span reference to a span.
 */
export declare function addChildSpanToSpan(span: SpanWithPotentialChildren, childSpan: Span): void;
/** This is only used internally by Idle Spans. */
export declare function removeChildSpanFromSpan(span: SpanWithPotentialChildren, childSpan: Span): void;
/**
 * Returns an array of the given span and all of its descendants.
 */
export declare function getSpanDescendants(span: SpanWithPotentialChildren): Span[];
/**
 * Returns the root span of a given span.
 */
export declare function getRootSpan(span: SpanWithPotentialChildren): Span;
/**
 * Returns the currently active span.
 */
export declare function getActiveSpan(): Span | undefined;
/**
 * Updates the metric summary on the currently active span
 */
export declare function updateMetricSummaryOnActiveSpan(metricType: MetricType, sanitizedName: string, value: number, unit: MeasurementUnit, tags: Record<string, Primitive>, bucketKey: string): void;
export {};
//# sourceMappingURL=spanUtils.d.ts.map
