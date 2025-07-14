import { FirstInputPolyfillCallback } from './types/polyfills';
export * from './types/base';
export * from './types/polyfills';
export * from './types/cls';
export * from './types/fcp';
export * from './types/fid';
export * from './types/inp';
export * from './types/lcp';
export * from './types/ttfb';
export interface WebVitalsGlobal {
    firstInputPolyfill: (onFirstInput: FirstInputPolyfillCallback) => void;
    resetFirstInputPolyfill: () => void;
    firstHiddenTime: number;
}
declare global {
    interface Window {
        webVitals: WebVitalsGlobal;
    }
}
interface PerformanceEntryMap {
    navigation: PerformanceNavigationTiming;
    resource: PerformanceResourceTiming;
    paint: PerformancePaintTiming;
}
declare global {
    interface Document {
        prerendering?: boolean;
        wasDiscarded?: boolean;
    }
    interface Performance {
        getEntriesByType<K extends keyof PerformanceEntryMap>(type: K): PerformanceEntryMap[K][];
    }
    interface PerformanceObserverInit {
        durationThreshold?: number;
    }
    interface PerformanceNavigationTiming {
        activationStart?: number;
    }
    interface PerformanceEventTiming extends PerformanceEntry {
        duration: DOMHighResTimeStamp;
        interactionId?: number;
    }
    interface LayoutShiftAttribution {
        node?: Node;
        previousRect: DOMRectReadOnly;
        currentRect: DOMRectReadOnly;
    }
    interface LayoutShift extends PerformanceEntry {
        value: number;
        sources: LayoutShiftAttribution[];
        hadRecentInput: boolean;
    }
    interface LargestContentfulPaint extends PerformanceEntry {
        renderTime: DOMHighResTimeStamp;
        loadTime: DOMHighResTimeStamp;
        size: number;
        id: string;
        url: string;
        element?: Element;
    }
}
//# sourceMappingURL=types.d.ts.map
