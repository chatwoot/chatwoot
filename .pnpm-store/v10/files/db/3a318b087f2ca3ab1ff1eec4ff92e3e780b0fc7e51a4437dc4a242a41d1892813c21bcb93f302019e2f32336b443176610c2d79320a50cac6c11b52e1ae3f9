import type { Scope } from '@sentry/core';
import { BaseClient } from '@sentry/core';
import type { BrowserClientProfilingOptions, BrowserClientReplayOptions, ClientOptions, Event, EventHint, Options, ParameterizedString, SeverityLevel, UserFeedback } from '@sentry/types';
import type { BrowserTransportOptions } from './transports/types';
/**
 * Configuration options for the Sentry Browser SDK.
 * @see @sentry/types Options for more information.
 */
export type BrowserOptions = Options<BrowserTransportOptions> & BrowserClientReplayOptions & BrowserClientProfilingOptions;
/**
 * Configuration options for the Sentry Browser SDK Client class
 * @see BrowserClient for more information.
 */
export type BrowserClientOptions = ClientOptions<BrowserTransportOptions> & BrowserClientReplayOptions & BrowserClientProfilingOptions & {
    /** If configured, this URL will be used as base URL for lazy loading integration. */
    cdnBaseUrl?: string;
};
/**
 * The Sentry Browser SDK Client.
 *
 * @see BrowserOptions for documentation on configuration options.
 * @see SentryClient for usage documentation.
 */
export declare class BrowserClient extends BaseClient<BrowserClientOptions> {
    /**
     * Creates a new Browser SDK instance.
     *
     * @param options Configuration options for this SDK.
     */
    constructor(options: BrowserClientOptions);
    /**
     * @inheritDoc
     */
    eventFromException(exception: unknown, hint?: EventHint): PromiseLike<Event>;
    /**
     * @inheritDoc
     */
    eventFromMessage(message: ParameterizedString, level?: SeverityLevel, hint?: EventHint): PromiseLike<Event>;
    /**
     * Sends user feedback to Sentry.
     *
     * @deprecated Use `captureFeedback` instead.
     */
    captureUserFeedback(feedback: UserFeedback): void;
    /**
     * @inheritDoc
     */
    protected _prepareEvent(event: Event, hint: EventHint, scope?: Scope): PromiseLike<Event | null>;
}
//# sourceMappingURL=client.d.ts.map