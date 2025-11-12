import { PostHogFetchOptions, PostHogFetchResponse, PostHogAutocaptureElement, PostHogFlagsResponse, PostHogCoreOptions, PostHogEventProperties, PostHogPersistedProperty, PostHogCaptureOptions, JsonType, PostHogRemoteConfig, FeatureFlagValue, PostHogFeatureFlagDetails, FeatureFlagDetail, SurveyResponse, PostHogGroupProperties } from './types';
import { RetriableOptions } from './utils';
import { SimpleEventEmitter } from './eventemitter';
export { getFeatureFlagValue } from './featureFlagUtils';
export * from './utils';
export declare const maybeAdd: (key: string, value: JsonType | undefined) => Record<string, JsonType>;
export declare function logFlushError(err: any): Promise<void>;
export declare abstract class PostHogCoreStateless {
    readonly apiKey: string;
    readonly host: string;
    readonly flushAt: number;
    readonly preloadFeatureFlags: boolean;
    readonly disableSurveys: boolean;
    private maxBatchSize;
    private maxQueueSize;
    private flushInterval;
    private flushPromise;
    private shutdownPromise;
    private requestTimeout;
    private featureFlagsRequestTimeoutMs;
    private remoteConfigRequestTimeoutMs;
    private removeDebugCallback?;
    private disableGeoip;
    private historicalMigration;
    protected disabled: boolean;
    protected disableCompression: boolean;
    private defaultOptIn;
    private pendingPromises;
    protected _events: SimpleEventEmitter;
    protected _flushTimer?: any;
    protected _retryOptions: RetriableOptions;
    protected _initPromise: Promise<void>;
    protected _isInitialized: boolean;
    protected _remoteConfigResponsePromise?: Promise<PostHogRemoteConfig | undefined>;
    abstract fetch(url: string, options: PostHogFetchOptions): Promise<PostHogFetchResponse>;
    abstract getLibraryId(): string;
    abstract getLibraryVersion(): string;
    abstract getCustomUserAgent(): string | void;
    abstract getPersistedProperty<T>(key: PostHogPersistedProperty): T | undefined;
    abstract setPersistedProperty<T>(key: PostHogPersistedProperty, value: T | null): void;
    constructor(apiKey: string, options?: PostHogCoreOptions);
    protected logMsgIfDebug(fn: () => void): void;
    protected wrap(fn: () => void): void;
    protected getCommonEventProperties(): PostHogEventProperties;
    get optedOut(): boolean;
    optIn(): Promise<void>;
    optOut(): Promise<void>;
    on(event: string, cb: (...args: any[]) => void): () => void;
    debug(enabled?: boolean): void;
    get isDebug(): boolean;
    get isDisabled(): boolean;
    private buildPayload;
    protected addPendingPromise<T>(promise: Promise<T>): Promise<T>;
    /***
     *** TRACKING
     ***/
    protected identifyStateless(distinctId: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    protected identifyStatelessImmediate(distinctId: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): Promise<void>;
    protected captureStateless(distinctId: string, event: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    protected captureStatelessImmediate(distinctId: string, event: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): Promise<void>;
    protected aliasStateless(alias: string, distinctId: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    protected aliasStatelessImmediate(alias: string, distinctId: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): Promise<void>;
    /***
     *** GROUPS
     ***/
    protected groupIdentifyStateless(groupType: string, groupKey: string | number, groupProperties?: PostHogEventProperties, options?: PostHogCaptureOptions, distinctId?: string, eventProperties?: PostHogEventProperties): void;
    protected getRemoteConfig(): Promise<PostHogRemoteConfig | undefined>;
    /***
     *** FEATURE FLAGS
     ***/
    protected getFlags(distinctId: string, groups?: Record<string, string | number>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, extraPayload?: Record<string, any>): Promise<PostHogFlagsResponse | undefined>;
    protected getFeatureFlagStateless(key: string, distinctId: string, groups?: Record<string, string>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean): Promise<{
        response: FeatureFlagValue | undefined;
        requestId: string | undefined;
    }>;
    protected getFeatureFlagDetailStateless(key: string, distinctId: string, groups?: Record<string, string>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean): Promise<{
        response: FeatureFlagDetail | undefined;
        requestId: string | undefined;
    } | undefined>;
    protected getFeatureFlagPayloadStateless(key: string, distinctId: string, groups?: Record<string, string>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean): Promise<JsonType | undefined>;
    protected getFeatureFlagPayloadsStateless(distinctId: string, groups?: Record<string, string>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean, flagKeysToEvaluate?: string[]): Promise<PostHogFlagsResponse['featureFlagPayloads'] | undefined>;
    protected getFeatureFlagsStateless(distinctId: string, groups?: Record<string, string | number>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean, flagKeysToEvaluate?: string[]): Promise<{
        flags: PostHogFlagsResponse['featureFlags'] | undefined;
        payloads: PostHogFlagsResponse['featureFlagPayloads'] | undefined;
        requestId: PostHogFlagsResponse['requestId'] | undefined;
    }>;
    protected getFeatureFlagsAndPayloadsStateless(distinctId: string, groups?: Record<string, string | number>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean, flagKeysToEvaluate?: string[]): Promise<{
        flags: PostHogFlagsResponse['featureFlags'] | undefined;
        payloads: PostHogFlagsResponse['featureFlagPayloads'] | undefined;
        requestId: PostHogFlagsResponse['requestId'] | undefined;
    }>;
    protected getFeatureFlagDetailsStateless(distinctId: string, groups?: Record<string, string | number>, personProperties?: Record<string, string>, groupProperties?: Record<string, Record<string, string>>, disableGeoip?: boolean, flagKeysToEvaluate?: string[]): Promise<PostHogFeatureFlagDetails | undefined>;
    /***
     *** SURVEYS
     ***/
    getSurveysStateless(): Promise<SurveyResponse['surveys']>;
    /***
     *** SUPER PROPERTIES
     ***/
    private _props;
    protected get props(): PostHogEventProperties;
    protected set props(val: PostHogEventProperties | undefined);
    register(properties: PostHogEventProperties): Promise<void>;
    unregister(property: string): Promise<void>;
    /***
     *** QUEUEING AND FLUSHING
     ***/
    protected enqueue(type: string, _message: any, options?: PostHogCaptureOptions): void;
    protected sendImmediate(type: string, _message: any, options?: PostHogCaptureOptions): Promise<void>;
    private prepareMessage;
    private clearFlushTimer;
    /**
     * Helper for flushing the queue in the background
     * Avoids unnecessary promise errors
     */
    private flushBackground;
    /**
     * Flushes the queue
     *
     * This function will return a promise that will resolve when the flush is complete,
     * or reject if there was an error (for example if the server or network is down).
     *
     * If there is already a flush in progress, this function will wait for that flush to complete.
     *
     * It's recommended to do error handling in the callback of the promise.
     *
     * @example
     * posthog.flush().then(() => {
     *   console.log('Flush complete')
     * }).catch((err) => {
     *   console.error('Flush failed', err)
     * })
     *
     *
     * @throws PostHogFetchHttpError
     * @throws PostHogFetchNetworkError
     * @throws Error
     */
    flush(): Promise<void>;
    protected getCustomHeaders(): {
        [key: string]: string;
    };
    private _flush;
    private fetchWithRetry;
    _shutdown(shutdownTimeoutMs?: number): Promise<void>;
    /**
     *  Call shutdown() once before the node process exits, so ensure that all events have been sent and all promises
     *  have resolved. Do not use this function if you intend to keep using this PostHog instance after calling it.
     * @param shutdownTimeoutMs
     */
    shutdown(shutdownTimeoutMs?: number): Promise<void>;
}
export declare abstract class PostHogCore extends PostHogCoreStateless {
    private sendFeatureFlagEvent;
    private flagCallReported;
    protected _flagsResponsePromise?: Promise<PostHogFlagsResponse | undefined>;
    protected _sessionExpirationTimeSeconds: number;
    private _sessionMaxLengthSeconds;
    protected sessionProps: PostHogEventProperties;
    constructor(apiKey: string, options?: PostHogCoreOptions);
    protected setupBootstrap(options?: Partial<PostHogCoreOptions>): void;
    private clearProps;
    on(event: string, cb: (...args: any[]) => void): () => void;
    reset(propertiesToKeep?: PostHogPersistedProperty[]): void;
    protected getCommonEventProperties(): PostHogEventProperties;
    private enrichProperties;
    /**
     * * @returns {string} The stored session ID for the current session. This may be an empty string if the client is not yet fully initialized.
     */
    getSessionId(): string;
    resetSessionId(): void;
    /**
     * * @returns {string} The stored anonymous ID. This may be an empty string if the client is not yet fully initialized.
     */
    getAnonymousId(): string;
    /**
     * * @returns {string} The stored distinct ID. This may be an empty string if the client is not yet fully initialized.
     */
    getDistinctId(): string;
    registerForSession(properties: PostHogEventProperties): void;
    unregisterForSession(property: string): void;
    /***
     *** TRACKING
     ***/
    identify(distinctId?: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    capture(event: string, properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    alias(alias: string): void;
    autocapture(eventType: string, elements: PostHogAutocaptureElement[], properties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    /***
     *** GROUPS
     ***/
    groups(groups: PostHogGroupProperties): void;
    group(groupType: string, groupKey: string | number, groupProperties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    groupIdentify(groupType: string, groupKey: string | number, groupProperties?: PostHogEventProperties, options?: PostHogCaptureOptions): void;
    /***
     * PROPERTIES
     ***/
    setPersonPropertiesForFlags(properties: {
        [type: string]: string;
    }): void;
    resetPersonPropertiesForFlags(): void;
    setGroupPropertiesForFlags(properties: {
        [type: string]: Record<string, string>;
    }): void;
    resetGroupPropertiesForFlags(): void;
    private remoteConfigAsync;
    /***
     *** FEATURE FLAGS
     ***/
    private flagsAsync;
    private cacheSessionReplay;
    private _remoteConfigAsync;
    private _flagsAsync;
    private setKnownFeatureFlagDetails;
    private getKnownFeatureFlagDetails;
    protected getKnownFeatureFlags(): PostHogFlagsResponse['featureFlags'] | undefined;
    private getKnownFeatureFlagPayloads;
    private getBootstrappedFeatureFlagDetails;
    private setBootstrappedFeatureFlagDetails;
    private getBootstrappedFeatureFlags;
    private getBootstrappedFeatureFlagPayloads;
    getFeatureFlag(key: string): FeatureFlagValue | undefined;
    getFeatureFlagPayload(key: string): JsonType | undefined;
    getFeatureFlagPayloads(): PostHogFlagsResponse['featureFlagPayloads'] | undefined;
    getFeatureFlags(): PostHogFlagsResponse['featureFlags'] | undefined;
    getFeatureFlagDetails(): PostHogFeatureFlagDetails | undefined;
    getFeatureFlagsAndPayloads(): {
        flags: PostHogFlagsResponse['featureFlags'] | undefined;
        payloads: PostHogFlagsResponse['featureFlagPayloads'] | undefined;
    };
    isFeatureEnabled(key: string): boolean | undefined;
    reloadFeatureFlags(options?: {
        cb?: (err?: Error, flags?: PostHogFlagsResponse['featureFlags']) => void;
    }): void;
    reloadRemoteConfigAsync(): Promise<PostHogRemoteConfig | undefined>;
    reloadFeatureFlagsAsync(sendAnonDistinctId?: boolean): Promise<PostHogFlagsResponse['featureFlags'] | undefined>;
    onFeatureFlags(cb: (flags: PostHogFlagsResponse['featureFlags']) => void): () => void;
    onFeatureFlag(key: string, cb: (value: FeatureFlagValue) => void): () => void;
    overrideFeatureFlag(flags: PostHogFlagsResponse['featureFlags'] | null): Promise<void>;
    /***
     *** ERROR TRACKING
     ***/
    captureException(error: unknown, additionalProperties?: PostHogEventProperties): void;
    /**
     * Capture written user feedback for a LLM trace. Numeric values are converted to strings.
     * @param traceId The trace ID to capture feedback for.
     * @param userFeedback The feedback to capture.
     */
    captureTraceFeedback(traceId: string | number, userFeedback: string): void;
    /**
     * Capture a metric for a LLM trace. Numeric values are converted to strings.
     * @param traceId The trace ID to capture the metric for.
     * @param metricName The name of the metric to capture.
     * @param metricValue The value of the metric to capture.
     */
    captureTraceMetric(traceId: string | number, metricName: string, metricValue: string | number | boolean): void;
}
export * from './types';
//# sourceMappingURL=index.d.ts.map