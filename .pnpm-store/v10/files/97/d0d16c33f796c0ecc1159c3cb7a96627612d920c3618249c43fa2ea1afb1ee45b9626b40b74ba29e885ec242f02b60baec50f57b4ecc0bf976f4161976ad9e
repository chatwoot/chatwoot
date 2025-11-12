export type FirstInputPolyfillEntry = Pick<PerformanceEventTiming, Exclude<keyof PerformanceEventTiming, 'processingEnd'>>;
export interface FirstInputPolyfillCallback {
    (entry: FirstInputPolyfillEntry): void;
}
export type NavigationTimingPolyfillEntry = Pick<PerformanceNavigationTiming, Exclude<keyof PerformanceNavigationTiming, 'initiatorType' | 'nextHopProtocol' | 'redirectCount' | 'transferSize' | 'encodedBodySize' | 'decodedBodySize' | 'type'>> & {
    type: PerformanceNavigationTiming['type'];
};
//# sourceMappingURL=polyfills.d.ts.map
