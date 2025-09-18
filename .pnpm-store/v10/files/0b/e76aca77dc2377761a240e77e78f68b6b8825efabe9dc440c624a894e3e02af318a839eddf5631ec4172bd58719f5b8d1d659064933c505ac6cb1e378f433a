import { Attachment } from './attachment';
import { Breadcrumb } from './breadcrumb';
import { Client } from './client';
import { Context, Contexts } from './context';
import { Event, EventHint } from './event';
import { EventProcessor } from './eventprocessor';
import { Extra, Extras } from './extra';
import { Primitive } from './misc';
import { RequestSession, Session } from './session';
import { SeverityLevel } from './severity';
import { Span } from './span';
import { PropagationContext } from './tracing';
import { User } from './user';
/** JSDocs */
export type CaptureContext = Scope | Partial<ScopeContext> | ((scope: Scope) => Scope);
/** JSDocs */
export interface ScopeContext {
    user: User;
    level: SeverityLevel;
    extra: Extras;
    contexts: Contexts;
    tags: {
        [key: string]: Primitive;
    };
    fingerprint: string[];
    requestSession: RequestSession;
    propagationContext: PropagationContext;
}
export interface ScopeData {
    eventProcessors: EventProcessor[];
    breadcrumbs: Breadcrumb[];
    user: User;
    tags: {
        [key: string]: Primitive;
    };
    extra: Extras;
    contexts: Contexts;
    attachments: Attachment[];
    propagationContext: PropagationContext;
    sdkProcessingMetadata: {
        [key: string]: unknown;
    };
    fingerprint: string[];
    level?: SeverityLevel;
    transactionName?: string;
    span?: Span;
}
/**
 * Holds additional event information.
 */
export interface Scope {
    /**
     * Update the client on the scope.
     */
    setClient(client: Client | undefined): void;
    /**
     * Get the client assigned to this scope.
     *
     * It is generally recommended to use the global function `Sentry.getClient()` instead, unless you know what you are doing.
     */
    getClient<C extends Client>(): C | undefined;
    /**
     * Sets the last event id on the scope.
     * @param lastEventId The last event id of a captured event.
     */
    setLastEventId(lastEventId: string | undefined): void;
    /**
     * This is the getter for lastEventId.
     * @returns The last event id of a captured event.
     */
    lastEventId(): string | undefined;
    /**
     * Add internal on change listener. Used for sub SDKs that need to store the scope.
     * @hidden
     */
    addScopeListener(callback: (scope: Scope) => void): void;
    /** Add new event processor that will be called during event processing. */
    addEventProcessor(callback: EventProcessor): this;
    /** Get the data of this scope, which is applied to an event during processing. */
    getScopeData(): ScopeData;
    /**
     * Updates user context information for future events.
     *
     * @param user User context object to be set in the current context. Pass `null` to unset the user.
     */
    setUser(user: User | null): this;
    /**
     * Returns the `User` if there is one
     */
    getUser(): User | undefined;
    /**
     * Set an object that will be merged sent as tags data with the event.
     * @param tags Tags context object to merge into current context.
     */
    setTags(tags: {
        [key: string]: Primitive;
    }): this;
    /**
     * Set key:value that will be sent as tags data with the event.
     *
     * Can also be used to unset a tag by passing `undefined`.
     *
     * @param key String key of tag
     * @param value Value of tag
     */
    setTag(key: string, value: Primitive): this;
    /**
     * Set an object that will be merged sent as extra data with the event.
     * @param extras Extras object to merge into current context.
     */
    setExtras(extras: Extras): this;
    /**
     * Set key:value that will be sent as extra data with the event.
     * @param key String of extra
     * @param extra Any kind of data. This data will be normalized.
     */
    setExtra(key: string, extra: Extra): this;
    /**
     * Sets the fingerprint on the scope to send with the events.
     * @param fingerprint string[] to group events in Sentry.
     */
    setFingerprint(fingerprint: string[]): this;
    /**
     * Sets the level on the scope for future events.
     * @param level string {@link SeverityLevel}
     */
    setLevel(level: SeverityLevel): this;
    /**
     * Sets the transaction name on the scope so that the name of the transaction
     * (e.g. taken server route or page location) is attached to future events.
     *
     * IMPORTANT: Calling this function does NOT change the name of the currently active
     * span. If you want to change the name of the active span, use `span.updateName()`
     * instead.
     *
     * By default, the SDK updates the scope's transaction name automatically on sensible
     * occasions, such as a page navigation or when handling a new request on the server.
     */
    setTransactionName(name?: string): this;
    /**
     * Sets context data with the given name.
     * @param name of the context
     * @param context an object containing context data. This data will be normalized. Pass `null` to unset the context.
     */
    setContext(name: string, context: Context | null): this;
    /**
     * Returns the `Session` if there is one
     */
    getSession(): Session | undefined;
    /**
     * Sets the `Session` on the scope
     */
    setSession(session?: Session): this;
    /**
     * Returns the `RequestSession` if there is one
     */
    getRequestSession(): RequestSession | undefined;
    /**
     * Sets the `RequestSession` on the scope
     */
    setRequestSession(requestSession?: RequestSession): this;
    /**
     * Updates the scope with provided data. Can work in three variations:
     * - plain object containing updatable attributes
     * - Scope instance that'll extract the attributes from
     * - callback function that'll receive the current scope as an argument and allow for modifications
     * @param captureContext scope modifier to be used
     */
    update(captureContext?: CaptureContext): this;
    /** Clears the current scope and resets its properties. */
    clear(): this;
    /**
     * Sets the breadcrumbs in the scope
     * @param breadcrumbs Breadcrumb
     * @param maxBreadcrumbs number of max breadcrumbs to merged into event.
     */
    addBreadcrumb(breadcrumb: Breadcrumb, maxBreadcrumbs?: number): this;
    /**
     * Get the last breadcrumb.
     */
    getLastBreadcrumb(): Breadcrumb | undefined;
    /**
     * Clears all currently set Breadcrumbs.
     */
    clearBreadcrumbs(): this;
    /**
     * Adds an attachment to the scope
     * @param attachment Attachment options
     */
    addAttachment(attachment: Attachment): this;
    /**
     * Clears attachments from the scope
     */
    clearAttachments(): this;
    /**
     * Add data which will be accessible during event processing but won't get sent to Sentry
     */
    setSDKProcessingMetadata(newData: {
        [key: string]: unknown;
    }): this;
    /**
     * Add propagation context to the scope, used for distributed tracing
     */
    setPropagationContext(context: PropagationContext): this;
    /**
     * Get propagation context from the scope, used for distributed tracing
     */
    getPropagationContext(): PropagationContext;
    /**
     * Capture an exception for this scope.
     *
     * @param exception The exception to capture.
     * @param hint Optinal additional data to attach to the Sentry event.
     * @returns the id of the captured Sentry event.
     */
    captureException(exception: unknown, hint?: EventHint): string;
    /**
     * Capture a message for this scope.
     *
     * @param message The message to capture.
     * @param level An optional severity level to report the message with.
     * @param hint Optional additional data to attach to the Sentry event.
     * @returns the id of the captured message.
     */
    captureMessage(message: string, level?: SeverityLevel, hint?: EventHint): string;
    /**
     * Capture a Sentry event for this scope.
     *
     * @param event The event to capture.
     * @param hint Optional additional data to attach to the Sentry event.
     * @returns the id of the captured event.
     */
    captureEvent(event: Event, hint?: EventHint): string;
    /**
     * Clone all data from this scope into a new scope.
     */
    clone(): Scope;
}
//# sourceMappingURL=scope.d.ts.map
