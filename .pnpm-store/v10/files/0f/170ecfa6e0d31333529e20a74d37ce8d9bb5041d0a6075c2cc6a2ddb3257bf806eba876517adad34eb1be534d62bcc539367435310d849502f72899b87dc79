import type { Breadcrumb, BreadcrumbHint, Client, ClientOptions, DataCategory, DsnComponents, DynamicSamplingContext, Envelope, Event, EventDropReason, EventHint, EventProcessor, FeedbackEvent, Integration, Outcome, ParameterizedString, SdkMetadata, Session, SessionAggregates, SeverityLevel, Span, SpanAttributes, SpanContextData, StartSpanOptions, Transport, TransportMakeRequestResponse } from '@sentry/types';
import type { IntegrationIndex } from './integration';
import type { Scope } from './scope';
/**
 * Base implementation for all JavaScript SDK clients.
 *
 * Call the constructor with the corresponding options
 * specific to the client subclass. To access these options later, use
 * {@link Client.getOptions}.
 *
 * If a Dsn is specified in the options, it will be parsed and stored. Use
 * {@link Client.getDsn} to retrieve the Dsn at any moment. In case the Dsn is
 * invalid, the constructor will throw a {@link SentryException}. Note that
 * without a valid Dsn, the SDK will not send any events to Sentry.
 *
 * Before sending an event, it is passed through
 * {@link BaseClient._prepareEvent} to add SDK information and scope data
 * (breadcrumbs and context). To add more custom information, override this
 * method and extend the resulting prepared event.
 *
 * To issue automatically created events (e.g. via instrumentation), use
 * {@link Client.captureEvent}. It will prepare the event and pass it through
 * the callback lifecycle. To issue auto-breadcrumbs, use
 * {@link Client.addBreadcrumb}.
 *
 * @example
 * class NodeClient extends BaseClient<NodeOptions> {
 *   public constructor(options: NodeOptions) {
 *     super(options);
 *   }
 *
 *   // ...
 * }
 */
export declare abstract class BaseClient<O extends ClientOptions> implements Client<O> {
    /** Options passed to the SDK. */
    protected readonly _options: O;
    /** The client Dsn, if specified in options. Without this Dsn, the SDK will be disabled. */
    protected readonly _dsn?: DsnComponents;
    protected readonly _transport?: Transport;
    /** Array of set up integrations. */
    protected _integrations: IntegrationIndex;
    /** Number of calls being processed */
    protected _numProcessing: number;
    protected _eventProcessors: EventProcessor[];
    /** Holds flushable  */
    private _outcomes;
    private _hooks;
    /**
     * Initializes this client instance.
     *
     * @param options Options for the client.
     */
    protected constructor(options: O);
    /**
     * @inheritDoc
     */
    captureException(exception: any, hint?: EventHint, scope?: Scope): string;
    /**
     * @inheritDoc
     */
    captureMessage(message: ParameterizedString, level?: SeverityLevel, hint?: EventHint, currentScope?: Scope): string;
    /**
     * @inheritDoc
     */
    captureEvent(event: Event, hint?: EventHint, currentScope?: Scope): string;
    /**
     * @inheritDoc
     */
    captureSession(session: Session): void;
    /**
     * @inheritDoc
     */
    getDsn(): DsnComponents | undefined;
    /**
     * @inheritDoc
     */
    getOptions(): O;
    /**
     * @see SdkMetadata in @sentry/types
     *
     * @return The metadata of the SDK
     */
    getSdkMetadata(): SdkMetadata | undefined;
    /**
     * @inheritDoc
     */
    getTransport(): Transport | undefined;
    /**
     * @inheritDoc
     */
    flush(timeout?: number): PromiseLike<boolean>;
    /**
     * @inheritDoc
     */
    close(timeout?: number): PromiseLike<boolean>;
    /** Get all installed event processors. */
    getEventProcessors(): EventProcessor[];
    /** @inheritDoc */
    addEventProcessor(eventProcessor: EventProcessor): void;
    /** @inheritdoc */
    init(): void;
    /**
     * Gets an installed integration by its name.
     *
     * @returns The installed integration or `undefined` if no integration with that `name` was installed.
     */
    getIntegrationByName<T extends Integration = Integration>(integrationName: string): T | undefined;
    /**
     * @inheritDoc
     */
    addIntegration(integration: Integration): void;
    /**
     * @inheritDoc
     */
    sendEvent(event: Event, hint?: EventHint): void;
    /**
     * @inheritDoc
     */
    sendSession(session: Session | SessionAggregates): void;
    /**
     * @inheritDoc
     */
    recordDroppedEvent(reason: EventDropReason, category: DataCategory, eventOrCount?: Event | number): void;
    /** @inheritdoc */
    on(hook: 'spanStart', callback: (span: Span) => void): () => void;
    /** @inheritdoc */
    on(hook: 'spanEnd', callback: (span: Span) => void): () => void;
    /** @inheritdoc */
    on(hook: 'idleSpanEnableAutoFinish', callback: (span: Span) => void): () => void;
    /** @inheritdoc */
    on(hook: 'beforeEnvelope', callback: (envelope: Envelope) => void): () => void;
    /** @inheritdoc */
    on(hook: 'beforeSendEvent', callback: (event: Event, hint?: EventHint) => void): () => void;
    /** @inheritdoc */
    on(hook: 'preprocessEvent', callback: (event: Event, hint?: EventHint) => void): () => void;
    /** @inheritdoc */
    on(hook: 'afterSendEvent', callback: (event: Event, sendResponse: TransportMakeRequestResponse) => void): () => void;
    /** @inheritdoc */
    on(hook: 'beforeAddBreadcrumb', callback: (breadcrumb: Breadcrumb, hint?: BreadcrumbHint) => void): () => void;
    /** @inheritdoc */
    on(hook: 'createDsc', callback: (dsc: DynamicSamplingContext, rootSpan?: Span) => void): () => void;
    /** @inheritdoc */
    on(hook: 'beforeSendFeedback', callback: (feedback: FeedbackEvent, options?: {
        includeReplay: boolean;
    }) => void): () => void;
    /** @inheritdoc */
    on(hook: 'beforeSampling', callback: (samplingData: {
        spanAttributes: SpanAttributes;
        spanName: string;
        parentSampled?: boolean;
        parentContext?: SpanContextData;
    }, samplingDecision: {
        decision: boolean;
    }) => void): void;
    /** @inheritdoc */
    on(hook: 'startPageLoadSpan', callback: (options: StartSpanOptions, traceOptions?: {
        sentryTrace?: string | undefined;
        baggage?: string | undefined;
    }) => void): () => void;
    /** @inheritdoc */
    on(hook: 'startNavigationSpan', callback: (options: StartSpanOptions) => void): () => void;
    on(hook: 'flush', callback: () => void): () => void;
    on(hook: 'close', callback: () => void): () => void;
    on(hook: 'applyFrameMetadata', callback: (event: Event) => void): () => void;
    /** @inheritdoc */
    emit(hook: 'beforeSampling', samplingData: {
        spanAttributes: SpanAttributes;
        spanName: string;
        parentSampled?: boolean;
        parentContext?: SpanContextData;
    }, samplingDecision: {
        decision: boolean;
    }): void;
    /** @inheritdoc */
    emit(hook: 'spanStart', span: Span): void;
    /** @inheritdoc */
    emit(hook: 'spanEnd', span: Span): void;
    /** @inheritdoc */
    emit(hook: 'idleSpanEnableAutoFinish', span: Span): void;
    /** @inheritdoc */
    emit(hook: 'beforeEnvelope', envelope: Envelope): void;
    /** @inheritdoc */
    emit(hook: 'beforeSendEvent', event: Event, hint?: EventHint): void;
    /** @inheritdoc */
    emit(hook: 'preprocessEvent', event: Event, hint?: EventHint): void;
    /** @inheritdoc */
    emit(hook: 'afterSendEvent', event: Event, sendResponse: TransportMakeRequestResponse): void;
    /** @inheritdoc */
    emit(hook: 'beforeAddBreadcrumb', breadcrumb: Breadcrumb, hint?: BreadcrumbHint): void;
    /** @inheritdoc */
    emit(hook: 'createDsc', dsc: DynamicSamplingContext, rootSpan?: Span): void;
    /** @inheritdoc */
    emit(hook: 'beforeSendFeedback', feedback: FeedbackEvent, options?: {
        includeReplay: boolean;
    }): void;
    /** @inheritdoc */
    emit(hook: 'startPageLoadSpan', options: StartSpanOptions, traceOptions?: {
        sentryTrace?: string | undefined;
        baggage?: string | undefined;
    }): void;
    /** @inheritdoc */
    emit(hook: 'startNavigationSpan', options: StartSpanOptions): void;
    /** @inheritdoc */
    emit(hook: 'flush'): void;
    /** @inheritdoc */
    emit(hook: 'close'): void;
    /** @inheritdoc */
    emit(hook: 'applyFrameMetadata', event: Event): void;
    /**
     * @inheritdoc
     */
    sendEnvelope(envelope: Envelope): PromiseLike<TransportMakeRequestResponse>;
    /** Setup integrations for this client. */
    protected _setupIntegrations(): void;
    /** Updates existing session based on the provided event */
    protected _updateSessionFromEvent(session: Session, event: Event): void;
    /**
     * Determine if the client is finished processing. Returns a promise because it will wait `timeout` ms before saying
     * "no" (resolving to `false`) in order to give the client a chance to potentially finish first.
     *
     * @param timeout The time, in ms, after which to resolve to `false` if the client is still busy. Passing `0` (or not
     * passing anything) will make the promise wait as long as it takes for processing to finish before resolving to
     * `true`.
     * @returns A promise which will resolve to `true` if processing is already done or finishes before the timeout, and
     * `false` otherwise
     */
    protected _isClientDoneProcessing(timeout?: number): PromiseLike<boolean>;
    /** Determines whether this SDK is enabled and a transport is present. */
    protected _isEnabled(): boolean;
    /**
     * Adds common information to events.
     *
     * The information includes release and environment from `options`,
     * breadcrumbs and context (extra, tags and user) from the scope.
     *
     * Information that is already present in the event is never overwritten. For
     * nested objects, such as the context, keys are merged.
     *
     * @param event The original event.
     * @param hint May contain additional information about the original exception.
     * @param currentScope A scope containing event metadata.
     * @returns A new event with more information.
     */
    protected _prepareEvent(event: Event, hint: EventHint, currentScope?: Scope, isolationScope?: import("@sentry/types").Scope): PromiseLike<Event | null>;
    /**
     * Processes the event and logs an error in case of rejection
     * @param event
     * @param hint
     * @param scope
     */
    protected _captureEvent(event: Event, hint?: EventHint, scope?: Scope): PromiseLike<string | undefined>;
    /**
     * Processes an event (either error or message) and sends it to Sentry.
     *
     * This also adds breadcrumbs and context information to the event. However,
     * platform specific meta data (such as the User's IP address) must be added
     * by the SDK implementor.
     *
     *
     * @param event The event to send to Sentry.
     * @param hint May contain additional information about the original exception.
     * @param currentScope A scope containing event metadata.
     * @returns A SyncPromise that resolves with the event or rejects in case event was/will not be send.
     */
    protected _processEvent(event: Event, hint: EventHint, currentScope?: Scope): PromiseLike<Event>;
    /**
     * Occupies the client with processing and event
     */
    protected _process<T>(promise: PromiseLike<T>): void;
    /**
     * Clears outcomes on this client and returns them.
     */
    protected _clearOutcomes(): Outcome[];
    /**
     * Sends client reports as an envelope.
     */
    protected _flushOutcomes(): void;
    /**
     * @inheritDoc
     */
    abstract eventFromException(_exception: any, _hint?: EventHint): PromiseLike<Event>;
    /**
     * @inheritDoc
     */
    abstract eventFromMessage(_message: ParameterizedString, _level?: SeverityLevel, _hint?: EventHint): PromiseLike<Event>;
}
//# sourceMappingURL=baseclient.d.ts.map