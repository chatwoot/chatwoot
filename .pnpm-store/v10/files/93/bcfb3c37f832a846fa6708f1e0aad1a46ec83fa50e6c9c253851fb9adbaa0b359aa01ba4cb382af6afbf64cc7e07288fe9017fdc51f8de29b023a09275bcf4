import { FirstInputPolyfillEntry, NavigationTimingPolyfillEntry } from '../types';
interface PerformanceEntryMap {
    event: PerformanceEventTiming[];
    paint: PerformancePaintTiming[];
    'layout-shift': LayoutShift[];
    'largest-contentful-paint': LargestContentfulPaint[];
    'first-input': PerformanceEventTiming[] | FirstInputPolyfillEntry[];
    navigation: PerformanceNavigationTiming[] | NavigationTimingPolyfillEntry[];
    resource: PerformanceResourceTiming[];
    longtask: PerformanceEntry[];
}
/**
 * Takes a performance entry type and a callback function, and creates a
 * `PerformanceObserver` instance that will observe the specified entry type
 * with buffering enabled and call the callback _for each entry_.
 *
 * This function also feature-detects entry support and wraps the logic in a
 * try/catch to avoid errors in unsupporting browsers.
 */
export declare const observe: <K extends keyof PerformanceEntryMap>(type: K, callback: (entries: PerformanceEntryMap[K]) => void, opts?: PerformanceObserverInit) => PerformanceObserver | undefined;
export {};
//# sourceMappingURL=observe.d.ts.map
