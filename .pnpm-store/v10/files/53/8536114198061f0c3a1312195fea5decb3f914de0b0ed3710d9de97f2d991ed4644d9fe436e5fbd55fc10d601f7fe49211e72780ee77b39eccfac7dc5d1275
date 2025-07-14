import { Span } from '@sentry/types';
interface StartTrackingWebVitalsOptions {
    recordClsStandaloneSpans: boolean;
}
/**
 * Start tracking web vitals.
 * The callback returned by this function can be used to stop tracking & ensure all measurements are final & captured.
 *
 * @returns A function that forces web vitals collection
 */
export declare function startTrackingWebVitals({ recordClsStandaloneSpans }: StartTrackingWebVitalsOptions): () => void;
/**
 * Start tracking long tasks.
 */
export declare function startTrackingLongTasks(): void;
/**
 * Start tracking long animation frames.
 */
export declare function startTrackingLongAnimationFrames(): void;
/**
 * Start tracking interaction events.
 */
export declare function startTrackingInteractions(): void;
export { startTrackingINP, registerInpInteractionListener } from './inp';
interface AddPerformanceEntriesOptions {
    /**
     * Flag to determine if CLS should be recorded as a measurement on the span or
     * sent as a standalone span instead.
     */
    recordClsOnPageloadSpan: boolean;
}
/** Add performance related spans to a transaction */
export declare function addPerformanceEntries(span: Span, options: AddPerformanceEntriesOptions): void;
/** Create measure related spans */
export declare function _addMeasureSpans(span: Span, entry: Record<string, any>, startTime: number, duration: number, timeOrigin: number): number;
export interface ResourceEntry extends Record<string, unknown> {
    initiatorType?: string;
    transferSize?: number;
    encodedBodySize?: number;
    decodedBodySize?: number;
    renderBlockingStatus?: string;
}
/** Create resource-related spans */
export declare function _addResourceSpans(span: Span, entry: ResourceEntry, resourceUrl: string, startTime: number, duration: number, timeOrigin: number): void;
//# sourceMappingURL=browserMetrics.d.ts.map
