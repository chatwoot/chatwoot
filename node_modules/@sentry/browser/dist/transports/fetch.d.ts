import { Event, Response, SentryRequest, Session, TransportOptions } from '@sentry/types';
import { BaseTransport } from './base';
import { FetchImpl } from './utils';
/** `fetch` based transport */
export declare class FetchTransport extends BaseTransport {
    /**
     * Fetch API reference which always points to native browser implementation.
     */
    private _fetch;
    constructor(options: TransportOptions, fetchImpl?: FetchImpl);
    /**
     * @param sentryRequest Prepared SentryRequest to be delivered
     * @param originalPayload Original payload used to create SentryRequest
     */
    protected _sendRequest(sentryRequest: SentryRequest, originalPayload: Event | Session): PromiseLike<Response>;
}
//# sourceMappingURL=fetch.d.ts.map