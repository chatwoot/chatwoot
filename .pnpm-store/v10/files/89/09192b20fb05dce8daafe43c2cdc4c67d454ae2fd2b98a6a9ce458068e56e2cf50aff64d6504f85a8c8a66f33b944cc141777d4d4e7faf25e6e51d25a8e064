import type { Breadcrumb, BreadcrumbHint } from './breadcrumb';
import type { Client } from './client';
import type { Event, EventHint } from './event';
import type { Extra, Extras } from './extra';
import type { Integration, IntegrationClass } from './integration';
import type { Primitive } from './misc';
import type { Scope } from './scope';
import type { Session } from './session';
import type { SeverityLevel } from './severity';
import type { User } from './user';
/**
 * Internal class used to make sure we always have the latest internal functions
 * working in case we have a version conflict.
 *
 * @deprecated This interface will be removed in a future major version of the SDK in favour of
 * `Scope` and `Client` objects and APIs.
 *
 * Most APIs referencing `Hub` are themselves and will be removed in version 8 of the SDK. More information:
 * - [Migration Guide](https://github.com/getsentry/sentry-javascript/blob/develop/MIGRATION.md#deprecate-hub)
 *
 */
export interface Hub {
    /**
     * This binds the given client to the current scope.
     * @param client An SDK client (client) instance.
     *
     * @deprecated Use `initAndBind()` directly.
     */
    bindClient(client?: Client): void;
    /**
     * Creates a new scope with and executes the given operation within.
     * The scope is automatically removed once the operation
     * finishes or throws.
     *
     * This is essentially a convenience function for:
     *
     *     pushScope();
     *     callback();
     *     popScope();
     *
     * @param callback that will be enclosed into push/popScope.
     *
     * @deprecated Use `Sentry.withScope()` instead.
     */
    withScope<T>(callback: (scope: Scope) => T): T;
    /**
     * Returns the client of the top stack.
     * @deprecated Use `Sentry.getClient()` instead.
     */
    getClient<C extends Client>(): C | undefined;
    /**
     * Returns the scope of the top stack.
     * @deprecated Use `Sentry.getCurrentScope()` instead.
     */
    getScope(): Scope;
    /**
     * Get the currently active isolation scope.
     * The isolation scope is used to isolate data between different hubs.
     *
     * @deprecated Use `Sentry.getIsolationScope()` instead.
     */
    getIsolationScope(): Scope;
    /**
     * Captures an exception event and sends it to Sentry.
     *
     * @param exception An exception-like object.
     * @param hint May contain additional information about the original exception.
     * @returns The generated eventId.
     *
     * @deprecated Use `Sentry.captureException()` instead.
     */
    captureException(exception: any, hint?: EventHint): string;
    /**
     * Captures a message event and sends it to Sentry.
     *
     * @param message The message to send to Sentry.
     * @param level Define the level of the message.
     * @param hint May contain additional information about the original exception.
     * @returns The generated eventId.
     *
     * @deprecated Use `Sentry.captureMessage()` instead.
     */
    captureMessage(message: string, level?: SeverityLevel, hint?: EventHint): string;
    /**
     * Captures a manually created event and sends it to Sentry.
     *
     * @param event The event to send to Sentry.
     * @param hint May contain additional information about the original exception.
     *
     * @deprecated Use `Sentry.captureEvent()` instead.
     */
    captureEvent(event: Event, hint?: EventHint): string;
    /**
     * Records a new breadcrumb which will be attached to future events.
     *
     * Breadcrumbs will be added to subsequent events to provide more context on
     * user's actions prior to an error or crash.
     *
     * @param breadcrumb The breadcrumb to record.
     * @param hint May contain additional information about the original breadcrumb.
     *
     * @deprecated Use `Sentry.addBreadcrumb()` instead.
     */
    addBreadcrumb(breadcrumb: Breadcrumb, hint?: BreadcrumbHint): void;
    /**
     * Updates user context information for future events.
     *
     * @param user User context object to be set in the current context. Pass `null` to unset the user.
     *
     * @deprecated Use `Sentry.setUser()` instead.
     */
    setUser(user: User | null): void;
    /**
     * Set an object that will be merged sent as tags data with the event.
     *
     * @param tags Tags context object to merge into current context.
     *
     * @deprecated Use `Sentry.setTags()` instead.
     */
    setTags(tags: {
        [key: string]: Primitive;
    }): void;
    /**
     * Set key:value that will be sent as tags data with the event.
     *
     * Can also be used to unset a tag, by passing `undefined`.
     *
     * @param key String key of tag
     * @param value Value of tag
     *
     * @deprecated Use `Sentry.setTag()` instead.
     */
    setTag(key: string, value: Primitive): void;
    /**
     * Set key:value that will be sent as extra data with the event.
     * @param key String of extra
     * @param extra Any kind of data. This data will be normalized.
     *
     * @deprecated Use `Sentry.setExtra()` instead.
     */
    setExtra(key: string, extra: Extra): void;
    /**
     * Set an object that will be merged sent as extra data with the event.
     * @param extras Extras object to merge into current context.
     *
     * @deprecated Use `Sentry.setExtras()` instead.
     */
    setExtras(extras: Extras): void;
    /**
     * Sets context data with the given name.
     * @param name of the context
     * @param context Any kind of data. This data will be normalized.
     *
     * @deprecated Use `Sentry.setContext()` instead.
     */
    setContext(name: string, context: {
        [key: string]: any;
    } | null): void;
    /**
     * Returns the integration if installed on the current client.
     *
     * @deprecated Use `Sentry.getClient().getIntegration()` instead.
     */
    getIntegration<T extends Integration>(integration: IntegrationClass<T>): T | null;
    /**
     * Starts a new `Session`, sets on the current scope and returns it.
     *
     * To finish a `session`, it has to be passed directly to `client.captureSession`, which is done automatically
     * when using `hub.endSession()` for the session currently stored on the scope.
     *
     * When there's already an existing session on the scope, it'll be automatically ended.
     *
     * @param context Optional properties of the new `Session`.
     *
     * @returns The session which was just started
     *
     * @deprecated Use top-level `startSession` instead.
     */
    startSession(context?: Session): Session;
    /**
     * Ends the session that lives on the current scope and sends it to Sentry
     *
     * @deprecated Use top-level `endSession` instead.
     */
    endSession(): void;
    /**
     * Sends the current session on the scope to Sentry
     *
     * @param endSession If set the session will be marked as exited and removed from the scope
     *
     * @deprecated Use top-level `captureSession` instead.
     */
    captureSession(endSession?: boolean): void;
}
//# sourceMappingURL=hub.d.ts.map