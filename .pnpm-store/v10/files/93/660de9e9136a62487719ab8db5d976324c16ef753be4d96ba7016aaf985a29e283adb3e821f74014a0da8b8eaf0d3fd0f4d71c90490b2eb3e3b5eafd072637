import type { Metric } from './base';
import type { NavigationTimingPolyfillEntry } from './polyfills';
/**
 * A TTFB-specific version of the Metric object.
 */
export interface TTFBMetric extends Metric {
    name: 'TTFB';
    entries: PerformanceNavigationTiming[] | NavigationTimingPolyfillEntry[];
}
/**
 * An object containing potentially-helpful debugging information that
 * can be sent along with the TTFB value for the current page visit in order
 * to help identify issues happening to real-users in the field.
 */
export interface TTFBAttribution {
    /**
     * The total time from when the user initiates loading the page to when the
     * DNS lookup begins. This includes redirects, service worker startup, and
     * HTTP cache lookup times.
     */
    waitingTime: number;
    /**
     * The total time to resolve the DNS for the current request.
     */
    dnsTime: number;
    /**
     * The total time to create the connection to the requested domain.
     */
    connectionTime: number;
    /**
     * The time time from when the request was sent until the first byte of the
     * response was received. This includes network time as well as server
     * processing time.
     */
    requestTime: number;
    /**
     * The `navigation` entry of the current page, which is useful for diagnosing
     * general page load issues. This can be used to access `serverTiming` for example:
     * navigationEntry?.serverTiming
     */
    navigationEntry?: PerformanceNavigationTiming | NavigationTimingPolyfillEntry;
}
/**
 * A TTFB-specific version of the Metric object with attribution.
 */
export interface TTFBMetricWithAttribution extends TTFBMetric {
    attribution: TTFBAttribution;
}
/**
 * A TTFB-specific version of the ReportCallback function.
 */
export interface TTFBReportCallback {
    (metric: TTFBMetric): void;
}
/**
 * A TTFB-specific version of the ReportCallback function with attribution.
 */
export interface TTFBReportCallbackWithAttribution {
    (metric: TTFBMetricWithAttribution): void;
}
//# sourceMappingURL=ttfb.d.ts.map