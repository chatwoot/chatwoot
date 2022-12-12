import { BaseTransportOptions, NewTransport } from '@sentry/core';
import { FetchImpl } from './utils';
export interface FetchTransportOptions extends BaseTransportOptions {
    requestOptions?: RequestInit;
}
/**
 * Creates a Transport that uses the Fetch API to send events to Sentry.
 */
export declare function makeNewFetchTransport(options: FetchTransportOptions, nativeFetch?: FetchImpl): NewTransport;
//# sourceMappingURL=new-fetch.d.ts.map