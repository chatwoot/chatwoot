import type { Attachment, Breadcrumb, CaptureContext, Client, Context, Contexts, Event, EventHint, EventProcessor, Extra, Extras, Primitive, PropagationContext, RequestSession, Scope as ScopeInterface, ScopeData, Session, SeverityLevel, User } from '@sentry/types';
/**
 * Holds additional event information.
 */
declare class ScopeClass implements ScopeInterface {
    /** Flag if notifying is happening. */
    protected _notifyingListeners: boolean;
    /** Callback for client to receive scope changes. */
    protected _scopeListeners: Array<(scope: Scope) => void>;
    /** Callback list that will be called during event processing. */
    protected _eventProcessors: EventProcessor[];
    /** Array of breadcrumbs. */
    protected _breadcrumbs: Breadcrumb[];
    /** User */
    protected _user: User;
    /** Tags */
    protected _tags: {
        [key: string]: Primitive;
    };
    /** Extra */
    protected _extra: Extras;
    /** Contexts */
    protected _contexts: Contexts;
    /** Attachments */
    protected _attachments: Attachment[];
    /** Propagation Context for distributed tracing */
    protected _propagationContext: PropagationContext;
    /**
     * A place to stash data which is needed at some point in the SDK's event processing pipeline but which shouldn't get
     * sent to Sentry
     */
    protected _sdkProcessingMetadata: {
        [key: string]: unknown;
    };
    /** Fingerprint */
    protected _fingerprint?: string[];
    /** Severity */
    protected _level?: SeverityLevel;
    /**
     * Transaction Name
     *
     * IMPORTANT: The transaction name on the scope has nothing to do with root spans/transaction objects.
     * It's purpose is to assign a transaction to the scope that's added to non-transaction events.
     */
    protected _transactionName?: string;
    /** Session */
    protected _session?: Session;
    /** Request Mode Session Status */
    protected _requestSession?: RequestSession;
    /** The client on this scope */
    protected _client?: Client;
    /** Contains the last event id of a captured event.  */
    protected _lastEventId?: string;
    constructor();
    /**
     * @inheritDoc
     */
    clone(): ScopeClass;
    /**
     * @inheritDoc
     */
    setClient(client: Client | undefined): void;
    /**
     * @inheritDoc
     */
    setLastEventId(lastEventId: string | undefined): void;
    /**
     * @inheritDoc
     */
    getClient<C extends Client>(): C | undefined;
    /**
     * @inheritDoc
     */
    lastEventId(): string | undefined;
    /**
     * @inheritDoc
     */
    addScopeListener(callback: (scope: Scope) => void): void;
    /**
     * @inheritDoc
     */
    addEventProcessor(callback: EventProcessor): this;
    /**
     * @inheritDoc
     */
    setUser(user: User | null): this;
    /**
     * @inheritDoc
     */
    getUser(): User | undefined;
    /**
     * @inheritDoc
     */
    getRequestSession(): RequestSession | undefined;
    /**
     * @inheritDoc
     */
    setRequestSession(requestSession?: RequestSession): this;
    /**
     * @inheritDoc
     */
    setTags(tags: {
        [key: string]: Primitive;
    }): this;
    /**
     * @inheritDoc
     */
    setTag(key: string, value: Primitive): this;
    /**
     * @inheritDoc
     */
    setExtras(extras: Extras): this;
    /**
     * @inheritDoc
     */
    setExtra(key: string, extra: Extra): this;
    /**
     * @inheritDoc
     */
    setFingerprint(fingerprint: string[]): this;
    /**
     * @inheritDoc
     */
    setLevel(level: SeverityLevel): this;
    /**
     * @inheritDoc
     */
    setTransactionName(name?: string): this;
    /**
     * @inheritDoc
     */
    setContext(key: string, context: Context | null): this;
    /**
     * @inheritDoc
     */
    setSession(session?: Session): this;
    /**
     * @inheritDoc
     */
    getSession(): Session | undefined;
    /**
     * @inheritDoc
     */
    update(captureContext?: CaptureContext): this;
    /**
     * @inheritDoc
     */
    clear(): this;
    /**
     * @inheritDoc
     */
    addBreadcrumb(breadcrumb: Breadcrumb, maxBreadcrumbs?: number): this;
    /**
     * @inheritDoc
     */
    getLastBreadcrumb(): Breadcrumb | undefined;
    /**
     * @inheritDoc
     */
    clearBreadcrumbs(): this;
    /**
     * @inheritDoc
     */
    addAttachment(attachment: Attachment): this;
    /**
     * @inheritDoc
     */
    clearAttachments(): this;
    /** @inheritDoc */
    getScopeData(): ScopeData;
    /**
     * @inheritDoc
     */
    setSDKProcessingMetadata(newData: {
        [key: string]: unknown;
    }): this;
    /**
     * @inheritDoc
     */
    setPropagationContext(context: PropagationContext): this;
    /**
     * @inheritDoc
     */
    getPropagationContext(): PropagationContext;
    /**
     * @inheritDoc
     */
    captureException(exception: unknown, hint?: EventHint): string;
    /**
     * @inheritDoc
     */
    captureMessage(message: string, level?: SeverityLevel, hint?: EventHint): string;
    /**
     * @inheritDoc
     */
    captureEvent(event: Event, hint?: EventHint): string;
    /**
     * This will be called on every set call.
     */
    protected _notifyScopeListeners(): void;
}
/**
 * Holds additional event information.
 */
export declare const Scope: typeof ScopeClass;
/**
 * Holds additional event information.
 */
export type Scope = ScopeInterface;
export {};
//# sourceMappingURL=scope.d.ts.map