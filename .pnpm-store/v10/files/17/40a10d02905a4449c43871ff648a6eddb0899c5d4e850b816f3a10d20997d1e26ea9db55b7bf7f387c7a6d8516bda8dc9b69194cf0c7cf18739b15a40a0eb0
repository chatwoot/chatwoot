import { Client, HandlerDataFetch, Scope, Span, SpanOrigin } from '@sentry/types';
type PolymorphicRequestHeaders = Record<string, string | undefined> | Array<[
    string,
    string
]> | {
    [key: string]: any;
    append: (key: string, value: string) => void;
    get: (key: string) => string | null | undefined;
};
/**
 * Create and track fetch request spans for usage in combination with `addFetchInstrumentationHandler`.
 *
 * @returns Span if a span was created, otherwise void.
 */
export declare function instrumentFetchRequest(handlerData: HandlerDataFetch, shouldCreateSpan: (url: string) => boolean, shouldAttachHeaders: (url: string) => boolean, spans: Record<string, Span>, spanOrigin?: SpanOrigin): Span | undefined;
/**
 * Adds sentry-trace and baggage headers to the various forms of fetch headers
 */
export declare function addTracingHeadersToFetchRequest(request: string | unknown, // unknown is actually type Request but we can't export DOM types from this package,
client: Client, scope: Scope, options: {
    headers?: {
        [key: string]: string[] | string | undefined;
    } | PolymorphicRequestHeaders;
}, span?: Span): PolymorphicRequestHeaders | undefined;
export {};
//# sourceMappingURL=fetch.d.ts.map
