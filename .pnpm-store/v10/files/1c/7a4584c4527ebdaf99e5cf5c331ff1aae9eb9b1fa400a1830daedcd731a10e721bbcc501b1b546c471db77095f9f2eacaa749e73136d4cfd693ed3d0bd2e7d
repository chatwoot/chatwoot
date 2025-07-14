import { Client, StartSpanOptions } from '@sentry/types';
import { Span } from '@sentry/types';
export declare const BROWSER_TRACING_INTEGRATION_ID = "BrowserTracing";
/** Options for Browser Tracing integration */
export interface BrowserTracingOptions {
    /**
     * The time that has to pass without any span being created.
     * If this time is exceeded, the idle span will finish.
     *
     * Default: 1000 (ms)
     */
    idleTimeout: number;
    /**
     * The max. time an idle span may run.
     * If this time is exceeded, the idle span will finish no matter what.
     *
     * Default: 30000 (ms)
     */
    finalTimeout: number;
    /**
     The max. time an idle span may run.
     * If this time is exceeded, the idle span will finish no matter what.
     *
     * Default: 15000 (ms)
     */
    childSpanTimeout: number;
    /**
     * If a span should be created on page load.
     * If this is set to `false`, this integration will not start the default page load span.
     * Default: true
     */
    instrumentPageLoad: boolean;
    /**
     * If a span should be created on navigation (history change).
     * If this is set to `false`, this integration will not start the default navigation spans.
     * Default: true
     */
    instrumentNavigation: boolean;
    /**
     * Flag spans where tabs moved to background with "cancelled". Browser background tab timing is
     * not suited towards doing precise measurements of operations. By default, we recommend that this option
     * be enabled as background transactions can mess up your statistics in nondeterministic ways.
     *
     * Default: true
     */
    markBackgroundSpan: boolean;
    /**
     * If true, Sentry will capture long tasks and add them to the corresponding transaction.
     *
     * Default: true
     */
    enableLongTask: boolean;
    /**
     * If true, Sentry will capture long animation frames and add them to the corresponding transaction.
     *
     * Default: false
     */
    enableLongAnimationFrame: boolean;
    /**
     * If true, Sentry will capture first input delay and add it to the corresponding transaction.
     *
     * Default: true
     */
    enableInp: boolean;
    /**
     * Flag to disable patching all together for fetch requests.
     *
     * Default: true
     */
    traceFetch: boolean;
    /**
     * Flag to disable patching all together for xhr requests.
     *
     * Default: true
     */
    traceXHR: boolean;
    /**
     * If true, Sentry will capture http timings and add them to the corresponding http spans.
     *
     * Default: true
     */
    enableHTTPTimings: boolean;
    /**
     * _experiments allows the user to send options to define how this integration works.
     *
     * Default: undefined
     */
    _experiments: Partial<{
        enableInteractions: boolean;
        enableStandaloneClsSpans: boolean;
    }>;
    /**
     * A callback which is called before a span for a pageload or navigation is started.
     * It receives the options passed to `startSpan`, and expects to return an updated options object.
     */
    beforeStartSpan?: (options: StartSpanOptions) => StartSpanOptions;
    /**
     * This function will be called before creating a span for a request with the given url.
     * Return false if you don't want a span for the given url.
     *
     * Default: (url: string) => true
     */
    shouldCreateSpanForRequest?(this: void, url: string): boolean;
}
/**
 * The Browser Tracing integration automatically instruments browser pageload/navigation
 * actions as transactions, and captures requests, metrics and errors as spans.
 *
 * The integration can be configured with a variety of options, and can be extended to use
 * any routing library.
 *
 * We explicitly export the proper type here, as this has to be extended in some cases.
 */
export declare const browserTracingIntegration: (_options?: Partial<BrowserTracingOptions>) => {
    name: string;
    afterAllSetup(client: Client<import("@sentry/types").ClientOptions<import("@sentry/types").BaseTransportOptions>>): void;
};
/**
 * Manually start a page load span.
 * This will only do something if a browser tracing integration integration has been setup.
 *
 * If you provide a custom `traceOptions` object, it will be used to continue the trace
 * instead of the default behavior, which is to look it up on the <meta> tags.
 */
export declare function startBrowserTracingPageLoadSpan(client: Client, spanOptions: StartSpanOptions, traceOptions?: {
    sentryTrace?: string | undefined;
    baggage?: string | undefined;
}): Span | undefined;
/**
 * Manually start a navigation span.
 * This will only do something if a browser tracing integration has been setup.
 */
export declare function startBrowserTracingNavigationSpan(client: Client, spanOptions: StartSpanOptions): Span | undefined;
/** Returns the value of a meta tag */
export declare function getMetaContent(metaName: string): string | undefined;
//# sourceMappingURL=browserTracingIntegration.d.ts.map
