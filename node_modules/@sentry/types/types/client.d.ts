import { DsnComponents } from './dsn';
import { Event, EventHint } from './event';
import { Integration, IntegrationClass } from './integration';
import { Options } from './options';
import { Scope } from './scope';
import { Session } from './session';
import { Severity } from './severity';
import { Transport } from './transport';
/**
 * User-Facing Sentry SDK Client.
 *
 * This interface contains all methods to interface with the SDK once it has
 * been installed. It allows to send events to Sentry, record breadcrumbs and
 * set a context included in every event. Since the SDK mutates its environment,
 * there will only be one instance during runtime.
 *
 */
export interface Client<O extends Options = Options> {
    /**
     * Captures an exception event and sends it to Sentry.
     *
     * @param exception An exception-like object.
     * @param hint May contain additional information about the original exception.
     * @param scope An optional scope containing event metadata.
     * @returns The event id
     */
    captureException(exception: any, hint?: EventHint, scope?: Scope): string | undefined;
    /**
     * Captures a message event and sends it to Sentry.
     *
     * @param message The message to send to Sentry.
     * @param level Define the level of the message.
     * @param hint May contain additional information about the original exception.
     * @param scope An optional scope containing event metadata.
     * @returns The event id
     */
    captureMessage(message: string, level?: Severity, hint?: EventHint, scope?: Scope): string | undefined;
    /**
     * Captures a manually created event and sends it to Sentry.
     *
     * @param event The event to send to Sentry.
     * @param hint May contain additional information about the original exception.
     * @param scope An optional scope containing event metadata.
     * @returns The event id
     */
    captureEvent(event: Event, hint?: EventHint, scope?: Scope): string | undefined;
    /** Captures a session
     *
     * @param session Session to be delivered
     */
    captureSession?(session: Session): void;
    /** Returns the current Dsn. */
    getDsn(): DsnComponents | undefined;
    /** Returns the current options. */
    getOptions(): O;
    /** Returns clients transport. */
    getTransport?(): Transport;
    /**
     * Flush the event queue and set the client to `enabled = false`. See {@link Client.flush}.
     *
     * @param timeout Maximum time in ms the client should wait before shutting down. Omitting this parameter will cause
     *   the client to wait until all events are sent before disabling itself.
     * @returns A promise which resolves to `true` if the flush completes successfully before the timeout, or `false` if
     * it doesn't.
     */
    close(timeout?: number): PromiseLike<boolean>;
    /**
     * Wait for all events to be sent or the timeout to expire, whichever comes first.
     *
     * @param timeout Maximum time in ms the client should wait for events to be flushed. Omitting this parameter will
     *   cause the client to wait until all events are sent before resolving the promise.
     * @returns A promise that will resolve with `true` if all events are sent before the timeout, or `false` if there are
     * still events in the queue when the timeout is reached.
     */
    flush(timeout?: number): PromiseLike<boolean>;
    /** Returns an array of installed integrations on the client. */
    getIntegration<T extends Integration>(integration: IntegrationClass<T>): T | null;
    /** This is an internal function to setup all integrations that should run on the client */
    setupIntegrations(): void;
}
//# sourceMappingURL=client.d.ts.map