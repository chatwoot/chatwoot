import type { Breadcrumb, BreadcrumbHint } from './breadcrumb';
import type { ErrorEvent, EventHint, TransactionEvent } from './event';
import type { Integration } from './integration';
import type { SamplingContext } from './samplingcontext';
import type { CaptureContext } from './scope';
import type { SdkMetadata } from './sdkmetadata';
import type { SpanJSON } from './span';
import type { StackLineParser, StackParser } from './stacktrace';
import type { TracePropagationTargets } from './tracing';
import type { BaseTransportOptions, Transport } from './transport';
export interface ClientOptions<TO extends BaseTransportOptions = BaseTransportOptions> {
    /**
     * Enable debug functionality in the SDK itself
     */
    debug?: boolean;
    /**
     * Specifies whether this SDK should send events to Sentry.
     * Defaults to true.
     */
    enabled?: boolean;
    /** Attaches stacktraces to pure capture message / log integrations */
    attachStacktrace?: boolean;
    /**
     * A flag enabling Sessions Tracking feature.
     * By default, Sessions Tracking is enabled.
     */
    autoSessionTracking?: boolean;
    /**
     * Send SDK Client Reports. When calling `Sentry.init()`, this option defaults to `true`.
     */
    sendClientReports?: boolean;
    /**
     * The Dsn used to connect to Sentry and identify the project. If omitted, the
     * SDK will not send any data to Sentry.
     */
    dsn?: string;
    /**
     * The release identifier used when uploading respective source maps. Specify
     * this value to allow Sentry to resolve the correct source maps when
     * processing events.
     */
    release?: string;
    /** The current environment of your application (e.g. "production"). */
    environment?: string;
    /** Sets the distribution for all events */
    dist?: string;
    /**
     * List of integrations that should be installed after SDK was initialized.
     */
    integrations: Integration[];
    /**
     * A function that takes transport options and returns the Transport object which is used to send events to Sentry.
     * The function is invoked internally when the client is initialized.
     */
    transport: (transportOptions: TO) => Transport;
    /**
     * A stack parser implementation
     * By default, a stack parser is supplied for all supported platforms
     */
    stackParser: StackParser;
    /**
     * Options for the default transport that the SDK uses.
     */
    transportOptions?: Partial<TO>;
    /**
     * Sample rate to determine trace sampling.
     *
     * 0.0 = 0% chance of a given trace being sent (send no traces) 1.0 = 100% chance of a given trace being sent (send
     * all traces)
     *
     * Tracing is enabled if either this or `tracesSampler` is defined. If both are defined, `tracesSampleRate` is
     * ignored.
     */
    tracesSampleRate?: number;
    /**
     * If this is enabled, spans and trace data will be generated and captured.
     * This will set the `tracesSampleRate` to the recommended default of `1.0` if `tracesSampleRate` is undefined.
     * Note that `tracesSampleRate` and `tracesSampler` take precedence over this option.
     *
     * @deprecated This option is deprecated and will be removed in the next major version. If you want to enable performance
     * monitoring, please use the `tracesSampleRate` or `tracesSampler` options instead. If you wan't to disable performance
     * monitoring, remove the `tracesSampler` and `tracesSampleRate` options.
     */
    enableTracing?: boolean;
    /**
     * If this is enabled, any spans started will always have their parent be the active root span,
     * if there is any active span.
     *
     * This is necessary because in some environments (e.g. browser),
     * we cannot guarantee an accurate active span.
     * Because we cannot properly isolate execution environments,
     * you may get wrong results when using e.g. nested `startSpan()` calls.
     *
     * To solve this, in these environments we'll by default enable this option.
     */
    parentSpanIsAlwaysRootSpan?: boolean;
    /**
     * Initial data to populate scope.
     */
    initialScope?: CaptureContext;
    /**
     * The maximum number of breadcrumbs sent with events. Defaults to 100.
     * Sentry has a maximum payload size of 1MB and any events exceeding that payload size will be dropped.
     */
    maxBreadcrumbs?: number;
    /**
     * A global sample rate to apply to all events.
     *
     * 0.0 = 0% chance of a given event being sent (send no events) 1.0 = 100% chance of a given event being sent (send
     * all events)
     */
    sampleRate?: number;
    /** Maximum number of chars a single value can have before it will be truncated. */
    maxValueLength?: number;
    /**
     * Maximum number of levels that normalization algorithm will traverse in objects and arrays.
     * Used when normalizing an event before sending, on all of the listed attributes:
     * - `breadcrumbs.data`
     * - `user`
     * - `contexts`
     * - `extra`
     * Defaults to `3`. Set to `0` to disable.
     */
    normalizeDepth?: number;
    /**
     * Maximum number of properties or elements that the normalization algorithm will output in any single array or object included in the normalized event.
     * Used when normalizing an event before sending, on all of the listed attributes:
     * - `breadcrumbs.data`
     * - `user`
     * - `contexts`
     * - `extra`
     * Defaults to `1000`
     */
    normalizeMaxBreadth?: number;
    /**
     * Controls how many milliseconds to wait before shutting down. The default is
     * SDK-specific but typically around 2 seconds. Setting this too low can cause
     * problems for sending events from command line applications. Setting it too
     * high can cause the application to block for users with network connectivity
     * problems.
     */
    shutdownTimeout?: number;
    /**
     * A pattern for error messages which should not be sent to Sentry.
     * By default, all errors will be sent.
     */
    ignoreErrors?: Array<string | RegExp>;
    /**
     * A pattern for transaction names which should not be sent to Sentry.
     * By default, all transactions will be sent.
     */
    ignoreTransactions?: Array<string | RegExp>;
    /**
     * A URL to an envelope tunnel endpoint. An envelope tunnel is an HTTP endpoint
     * that accepts Sentry envelopes for forwarding. This can be used to force data
     * through a custom server independent of the type of data.
     */
    tunnel?: string;
    /**
     * Controls if potentially sensitive data should be sent to Sentry by default.
     * Note that this only applies to data that the SDK is sending by default
     * but not data that was explicitly set (e.g. by calling `Sentry.setUser()`).
     *
     * Defaults to `false`.
     *
     * NOTE: This option currently controls only a few data points in a selected
     * set of SDKs. The goal for this option is to eventually control all sensitive
     * data the SDK sets by default. However, this would be a breaking change so
     * until the next major update this option only controls data points which were
     * added in versions above `7.9.0`.
     */
    sendDefaultPii?: boolean;
    /**
     * Set of metadata about the SDK that can be internally used to enhance envelopes and events,
     * and provide additional data about every request.
     */
    _metadata?: SdkMetadata;
    /**
     * Options which are in beta, or otherwise not guaranteed to be stable.
     */
    _experiments?: {
        [key: string]: any;
    };
    /**
     * A pattern for error URLs which should exclusively be sent to Sentry.
     * This is the opposite of {@link Options.denyUrls}.
     * By default, all errors will be sent.
     *
     * Requires the use of the `InboundFilters` integration.
     */
    allowUrls?: Array<string | RegExp>;
    /**
     * A pattern for error URLs which should not be sent to Sentry.
     * To allow certain errors instead, use {@link Options.allowUrls}.
     * By default, all errors will be sent.
     *
     * Requires the use of the `InboundFilters` integration.
     */
    denyUrls?: Array<string | RegExp>;
    /**
     * List of strings and/or Regular Expressions used to determine which outgoing requests will have `sentry-trace` and `baggage`
     * headers attached.
     *
     * **Default:** If this option is not provided, tracing headers will be attached to all outgoing requests.
     * If you are using a browser SDK, by default, tracing headers will only be attached to outgoing requests to the same origin.
     *
     * **Disclaimer:** Carelessly setting this option in browser environments may result into CORS errors!
     * Only attach tracing headers to requests to the same origin, or to requests to services you can control CORS headers of.
     * Cross-origin requests, meaning requests to a different domain, for example a request to `https://api.example.com/` while you're on `https://example.com/`, take special care.
     * If you are attaching headers to cross-origin requests, make sure the backend handling the request returns a `"Access-Control-Allow-Headers: sentry-trace, baggage"` header to ensure your requests aren't blocked.
     *
     * If you provide a `tracePropagationTargets` array, the entries you provide will be matched against the entire URL of the outgoing request.
     * If you are using a browser SDK, the entries will also be matched against the pathname of the outgoing requests.
     * This is so you can have matchers for relative requests, for example, `/^\/api/` if you want to trace requests to your `/api` routes on the same domain.
     *
     * If any of the two match any of the provided values, tracing headers will be attached to the outgoing request.
     * Both, the string values, and the RegExes you provide in the array will match if they partially match the URL or pathname.
     *
     * Examples:
     * - `tracePropagationTargets: [/^\/api/]` and request to `https://same-origin.com/api/posts`:
     *   - Tracing headers will be attached because the request is sent to the same origin and the regex matches the pathname "/api/posts".
     * - `tracePropagationTargets: [/^\/api/]` and request to `https://different-origin.com/api/posts`:
     *   - Tracing headers will not be attached because the pathname will only be compared when the request target lives on the same origin.
     * - `tracePropagationTargets: [/^\/api/, 'https://external-api.com']` and request to `https://external-api.com/v1/data`:
     *   - Tracing headers will be attached because the request URL matches the string `'https://external-api.com'`.
     */
    tracePropagationTargets?: TracePropagationTargets;
    /**
     * Function to compute tracing sample rate dynamically and filter unwanted traces.
     *
     * Tracing is enabled if either this or `tracesSampleRate` is defined. If both are defined, `tracesSampleRate` is
     * ignored.
     *
     * Will automatically be passed a context object of default and optional custom data. See
     * {@link Transaction.samplingContext} and {@link Hub.startTransaction}.
     *
     * @returns A sample rate between 0 and 1 (0 drops the trace, 1 guarantees it will be sent). Returning `true` is
     * equivalent to returning 1 and returning `false` is equivalent to returning 0.
     */
    tracesSampler?: (samplingContext: SamplingContext) => number | boolean;
    /**
     * An event-processing callback for error and message events, guaranteed to be invoked after all other event
     * processors, which allows an event to be modified or dropped.
     *
     * Note that you must return a valid event from this callback. If you do not wish to modify the event, simply return
     * it at the end. Returning `null` will cause the event to be dropped.
     *
     * @param event The error or message event generated by the SDK.
     * @param hint Event metadata useful for processing.
     * @returns A new event that will be sent | null.
     */
    beforeSend?: (event: ErrorEvent, hint: EventHint) => PromiseLike<ErrorEvent | null> | ErrorEvent | null;
    /**
     * This function can be defined to modify or entirely drop a child span before it's sent.
     * Returning `null` will cause this span to be dropped.
     *
     * Note that this function is only called for child spans and not for the root span (formerly known as transaction).
     * If you want to modify or drop the root span, use {@link Options.beforeSendTransaction} instead.
     *
     * @param span The span generated by the SDK.
     *
     * @returns A new span that will be sent or null if the span should not be sent.
     */
    beforeSendSpan?: (span: SpanJSON) => SpanJSON | null;
    /**
     * An event-processing callback for transaction events, guaranteed to be invoked after all other event
     * processors. This allows an event to be modified or dropped before it's sent.
     *
     * Note that you must return a valid event from this callback. If you do not wish to modify the event, simply return
     * it at the end. Returning `null` will cause the event to be dropped.
     *
     * @param event The error or message event generated by the SDK.
     * @param hint Event metadata useful for processing.
     * @returns A new event that will be sent | null.
     */
    beforeSendTransaction?: (event: TransactionEvent, hint: EventHint) => PromiseLike<TransactionEvent | null> | TransactionEvent | null;
    /**
     * A callback invoked when adding a breadcrumb, allowing to optionally modify
     * it before adding it to future events.
     *
     * Note that you must return a valid breadcrumb from this callback. If you do
     * not wish to modify the breadcrumb, simply return it at the end.
     * Returning null will cause the breadcrumb to be dropped.
     *
     * @param breadcrumb The breadcrumb as created by the SDK.
     * @returns The breadcrumb that will be added | null.
     */
    beforeBreadcrumb?: (breadcrumb: Breadcrumb, hint?: BreadcrumbHint) => Breadcrumb | null;
}
/** Base configuration options for every SDK. */
export interface Options<TO extends BaseTransportOptions = BaseTransportOptions> extends Omit<Partial<ClientOptions<TO>>, 'integrations' | 'transport' | 'stackParser'> {
    /**
     * If this is set to false, default integrations will not be added, otherwise this will internally be set to the
     * recommended default integrations.
     */
    defaultIntegrations?: false | Integration[];
    /**
     * List of integrations that should be installed after SDK was initialized.
     * Accepts either a list of integrations or a function that receives
     * default integrations and returns a new, updated list.
     */
    integrations?: Integration[] | ((integrations: Integration[]) => Integration[]);
    /**
     * A function that takes transport options and returns the Transport object which is used to send events to Sentry.
     * The function is invoked internally during SDK initialization.
     * By default, the SDK initializes its default transports.
     */
    transport?: (transportOptions: TO) => Transport;
    /**
     * A stack parser implementation or an array of stack line parsers
     * By default, a stack parser is supplied for all supported browsers
     */
    stackParser?: StackParser | StackLineParser[];
}
//# sourceMappingURL=options.d.ts.map