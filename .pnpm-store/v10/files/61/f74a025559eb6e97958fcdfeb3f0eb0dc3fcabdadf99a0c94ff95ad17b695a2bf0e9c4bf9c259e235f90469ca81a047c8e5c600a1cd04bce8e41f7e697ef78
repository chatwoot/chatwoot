import type { LoadState, Metric } from './base';
/**
 * An INP-specific version of the Metric object.
 */
export interface INPMetric extends Metric {
    name: 'INP';
    entries: PerformanceEventTiming[];
}
/**
 * An object containing potentially-helpful debugging information that
 * can be sent along with the INP value for the current page visit in order
 * to help identify issues happening to real-users in the field.
 */
export interface INPAttribution {
    /**
     * A selector identifying the element that the user interacted with for
     * the event corresponding to INP. This element will be the `target` of the
     * `event` dispatched.
     */
    eventTarget?: string;
    /**
     * The time when the user interacted for the event corresponding to INP.
     * This time will match the `timeStamp` value of the `event` dispatched.
     */
    eventTime?: number;
    /**
     * The `type` of the `event` dispatched corresponding to INP.
     */
    eventType?: string;
    /**
     * The `PerformanceEventTiming` entry corresponding to INP.
     */
    eventEntry?: PerformanceEventTiming;
    /**
     * The loading state of the document at the time when the event corresponding
     * to INP occurred (see `LoadState` for details). If the interaction occurred
     * while the document was loading and executing script (e.g. usually in the
     * `dom-interactive` phase) it can result in long delays.
     */
    loadState?: LoadState;
}
/**
 * An INP-specific version of the Metric object with attribution.
 */
export interface INPMetricWithAttribution extends INPMetric {
    attribution: INPAttribution;
}
/**
 * An INP-specific version of the ReportCallback function.
 */
export interface INPReportCallback {
    (metric: INPMetric): void;
}
/**
 * An INP-specific version of the ReportCallback function with attribution.
 */
export interface INPReportCallbackWithAttribution {
    (metric: INPMetricWithAttribution): void;
}
//# sourceMappingURL=inp.d.ts.map