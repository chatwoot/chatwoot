import { Event, Response, SentryRequest, Session } from '@sentry/types';
import { BaseTransport } from './base';
/** `XHR` based transport */
export declare class XHRTransport extends BaseTransport {
    /**
     * @param sentryRequest Prepared SentryRequest to be delivered
     * @param originalPayload Original payload used to create SentryRequest
     */
    protected _sendRequest(sentryRequest: SentryRequest, originalPayload: Event | Session): PromiseLike<Response>;
}
//# sourceMappingURL=xhr.d.ts.map