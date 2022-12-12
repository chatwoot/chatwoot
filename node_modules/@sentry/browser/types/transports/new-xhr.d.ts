import { BaseTransportOptions, NewTransport } from '@sentry/core';
export interface XHRTransportOptions extends BaseTransportOptions {
    headers?: {
        [key: string]: string;
    };
}
/**
 * Creates a Transport that uses the XMLHttpRequest API to send events to Sentry.
 */
export declare function makeNewXHRTransport(options: XHRTransportOptions): NewTransport;
//# sourceMappingURL=new-xhr.d.ts.map