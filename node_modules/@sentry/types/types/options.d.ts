import { Breadcrumb, BreadcrumbHint } from './breadcrumb';
import { Event, EventHint } from './event';
import { Integration } from './integration';
import { CaptureContext } from './scope';
import { SdkMetadata } from './sdkmetadata';
import { SamplingContext } from './transaction';
import { Transport, TransportClass, TransportOptions } from './transport';
/** Base configuration options for every SDK. */
export interface Options {
    /**
     * Enable debug functionality in the SDK itself
     */
    debug?: boolean;
    /**
     * Specifies whether this SDK should send events to Sentry.
     * Defaults to true.
     */
    enabled?: boolean;
    /**
     * The Dsn used to connect to Sentry and identify the project. If omitted, the
     * SDK will not send any data to Sentry.
     */
    dsn?: string;
    /**
     * If this is set to false, default integrations will not be added, otherwise this will internally be set to the
     * recommended default integrations.
     * TODO: We should consider changing this to `boolean | Integration[]`
     */
    defaultIntegrations?: false | Integration[];
    /**
     * List of integrations that should be installed after SDK was initialized.
     * Accepts either a list of integrations or a function that receives
     * default integrations and returns a new, updated list.
     */
    integrations?: Integration[] | ((integrations: Integration[]) => Integration[]);
    /**
     * A pattern for error messages which should not be sent to Sentry.
     * By default, all errors will be sent.
     */
    ignoreErrors?: Array<string | RegExp>;
    /**
     * Transport object that should be used to send events to Sentry
     */
    transport?: TransportClass<Transport>;
    /**
     * Options for the default transport that the SDK uses.
     */
    transportOptions?: TransportOptions;
    /**
     * A URL to an envelope tunnel endpoint. An envelope tunnel is an HTTP endpoint
     * that accepts Sentry envelopes for forwarding. This can be used to force data
     * through a custom server independent of the type of data.
     */
    tunnel?: string;
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
     * The maximum number of breadcrumbs sent with events. Defaults to 100.
     * Values over 100 will be ignored and 100 used instead.
     */
    maxBreadcrumbs?: number;
    /** A global sample rate to apply to all events (0 - 1). */
    sampleRate?: number;
    /** Attaches stacktraces to pure capture message / log integrations */
    attachStacktrace?: boolean;
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
     * A flag enabling Sessions Tracking feature.
     * By default, Sessions Tracking is enabled.
     */
    autoSessionTracking?: boolean;
    /**
     * Send SDK Client Reports.
     * By default, Client Reports are enabled.
     */
    sendClientReports?: boolean;
    /**
     * Initial data to populate scope.
     */
    initialScope?: CaptureContext;
    /**
     * Set of metadata about the SDK that can be internally used to enhance envelopes and events,
     * and provide additional data about every request.
     * */
    _metadata?: SdkMetadata;
    /**
     * Options which are in beta, or otherwise not guaranteed to be stable.
     */
    _experiments?: {
        [key: string]: any;
    };
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
     * A callback invoked during event submission, allowing to optionally modify
     * the event before it is sent to Sentry.
     *
     * Note that you must return a valid event from this callback. If you do not
     * wish to modify the event, simply return it at the end.
     * Returning null will cause the event to be dropped.
     *
     * @param event The error or message event generated by the SDK.
     * @param hint May contain additional information about the original exception.
     * @returns A new event that will be sent | null.
     */
    beforeSend?: (event: Event, hint?: EventHint) => PromiseLike<Event | null> | Event | null;
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
//# sourceMappingURL=options.d.ts.map