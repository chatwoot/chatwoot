import { Envelope, EventStatus } from '@sentry/types';
import { PromiseBuffer } from '@sentry/utils';
export declare const ERROR_TRANSPORT_CATEGORY = "error";
export declare const TRANSACTION_TRANSPORT_CATEGORY = "transaction";
export declare const ATTACHMENT_TRANSPORT_CATEGORY = "attachment";
export declare const SESSION_TRANSPORT_CATEGORY = "session";
declare type TransportCategory = typeof ERROR_TRANSPORT_CATEGORY | typeof TRANSACTION_TRANSPORT_CATEGORY | typeof ATTACHMENT_TRANSPORT_CATEGORY | typeof SESSION_TRANSPORT_CATEGORY;
export declare type TransportRequest = {
    body: string;
    category: TransportCategory;
};
export declare type TransportMakeRequestResponse = {
    body?: string;
    headers?: {
        [key: string]: string | null;
        'x-sentry-rate-limits': string | null;
        'retry-after': string | null;
    };
    reason?: string;
    statusCode: number;
};
export declare type TransportResponse = {
    status: EventStatus;
    reason?: string;
};
interface InternalBaseTransportOptions {
    bufferSize?: number;
}
export interface BaseTransportOptions extends InternalBaseTransportOptions {
    url: string;
}
export interface BrowserTransportOptions extends BaseTransportOptions {
    fetchParams: Record<string, string>;
    headers?: Record<string, string>;
    sendClientReports?: boolean;
}
export interface NewTransport {
    send(request: Envelope): PromiseLike<TransportResponse>;
    flush(timeout?: number): PromiseLike<boolean>;
}
export declare type TransportRequestExecutor = (request: TransportRequest) => PromiseLike<TransportMakeRequestResponse>;
export declare const DEFAULT_TRANSPORT_BUFFER_SIZE = 30;
/**
 * Creates a `NewTransport`
 *
 * @param options
 * @param makeRequest
 */
export declare function createTransport(options: InternalBaseTransportOptions, makeRequest: TransportRequestExecutor, buffer?: PromiseBuffer<TransportResponse>): NewTransport;
export {};
//# sourceMappingURL=base.d.ts.map