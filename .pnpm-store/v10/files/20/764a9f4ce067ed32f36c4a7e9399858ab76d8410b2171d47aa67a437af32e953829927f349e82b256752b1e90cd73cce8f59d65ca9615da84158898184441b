import { Event, ExtractedNodeRequestData, PolymorphicRequest, TransactionSource, WebFetchHeaders, WebFetchRequest } from '@sentry/types';
declare const DEFAULT_REQUEST_INCLUDES: string[];
export declare const DEFAULT_USER_INCLUDES: string[];
/**
 * Options deciding what parts of the request to use when enhancing an event
 */
export type AddRequestDataToEventOptions = {
    /** Flags controlling whether each type of data should be added to the event */
    include?: {
        ip?: boolean;
        request?: boolean | Array<(typeof DEFAULT_REQUEST_INCLUDES)[number]>;
        transaction?: boolean | TransactionNamingScheme;
        user?: boolean | Array<(typeof DEFAULT_USER_INCLUDES)[number]>;
    };
    /** Injected platform-specific dependencies */
    deps?: {
        cookie: {
            parse: (cookieStr: string) => Record<string, string>;
        };
        url: {
            parse: (urlStr: string) => {
                query: string | null;
            };
        };
    };
};
export type TransactionNamingScheme = 'path' | 'methodPath' | 'handler';
/**
 * Extracts a complete and parameterized path from the request object and uses it to construct transaction name.
 * If the parameterized transaction name cannot be extracted, we fall back to the raw URL.
 *
 * Additionally, this function determines and returns the transaction name source
 *
 * eg. GET /mountpoint/user/:id
 *
 * @param req A request object
 * @param options What to include in the transaction name (method, path, or a custom route name to be
 *                used instead of the request's route)
 *
 * @returns A tuple of the fully constructed transaction name [0] and its source [1] (can be either 'route' or 'url')
 */
export declare function extractPathForTransaction(req: PolymorphicRequest, options?: {
    path?: boolean;
    method?: boolean;
    customRoute?: string;
}): [
    string,
    TransactionSource
];
/**
 * Normalize data from the request object, accounting for framework differences.
 *
 * @param req The request object from which to extract data
 * @param options.include An optional array of keys to include in the normalized data. Defaults to
 * DEFAULT_REQUEST_INCLUDES if not provided.
 * @param options.deps Injected, platform-specific dependencies
 * @returns An object containing normalized request data
 */
export declare function extractRequestData(req: PolymorphicRequest, options?: {
    include?: string[];
}): ExtractedNodeRequestData;
/**
 * Add data from the given request to the given event
 *
 * @param event The event to which the request data will be added
 * @param req Request object
 * @param options.include Flags to control what data is included
 * @param options.deps Injected platform-specific dependencies
 * @returns The mutated `Event` object
 */
export declare function addRequestDataToEvent(event: Event, req: PolymorphicRequest, options?: AddRequestDataToEventOptions): Event;
/**
 * Transforms a `Headers` object that implements the `Web Fetch API` (https://developer.mozilla.org/en-US/docs/Web/API/Headers) into a simple key-value dict.
 * The header keys will be lower case: e.g. A "Content-Type" header will be stored as "content-type".
 */
export declare function winterCGHeadersToDict(winterCGHeaders: WebFetchHeaders): Record<string, string>;
/**
 * Converts a `Request` object that implements the `Web Fetch API` (https://developer.mozilla.org/en-US/docs/Web/API/Headers) into the format that the `RequestData` integration understands.
 */
export declare function winterCGRequestToRequestData(req: WebFetchRequest): PolymorphicRequest;
export {};
//# sourceMappingURL=requestdata.d.ts.map
