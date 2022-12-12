import { DsnComponents, DsnLike, SdkMetadata } from '@sentry/types';
/**
 * Stores details about a Sentry SDK
 */
export interface APIDetails {
    /** The DSN as passed to Sentry.init() */
    initDsn: DsnLike;
    /** Metadata about the SDK (name, version, etc) for inclusion in envelope headers */
    metadata: SdkMetadata;
    /** The internally used Dsn object. */
    readonly dsn: DsnComponents;
    /** The envelope tunnel to use. */
    readonly tunnel?: string;
}
/**
 * Helper class to provide urls, headers and metadata that can be used to form
 * different types of requests to Sentry endpoints.
 * Supports both envelopes and regular event requests.
 *
 * @deprecated Please use APIDetails
 **/
export declare class API {
    /** The DSN as passed to Sentry.init() */
    dsn: DsnLike;
    /** Metadata about the SDK (name, version, etc) for inclusion in envelope headers */
    metadata: SdkMetadata;
    /** The internally used Dsn object. */
    private readonly _dsnObject;
    /** The envelope tunnel to use. */
    private readonly _tunnel?;
    /** Create a new instance of API */
    constructor(dsn: DsnLike, metadata?: SdkMetadata, tunnel?: string);
    /** Returns the Dsn object. */
    getDsn(): DsnComponents;
    /** Does this transport force envelopes? */
    forceEnvelope(): boolean;
    /** Returns the prefix to construct Sentry ingestion API endpoints. */
    getBaseApiEndpoint(): string;
    /** Returns the store endpoint URL. */
    getStoreEndpoint(): string;
    /**
     * Returns the store endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    getStoreEndpointWithUrlEncodedAuth(): string;
    /**
     * Returns the envelope endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    getEnvelopeEndpointWithUrlEncodedAuth(): string;
}
/** Initializes API Details */
export declare function initAPIDetails(dsn: DsnLike, metadata?: SdkMetadata, tunnel?: string): APIDetails;
/**
 * Returns the store endpoint URL with auth in the query string.
 *
 * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
 */
export declare function getStoreEndpointWithUrlEncodedAuth(dsn: DsnComponents): string;
/**
 * Returns the envelope endpoint URL with auth in the query string.
 *
 * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
 */
export declare function getEnvelopeEndpointWithUrlEncodedAuth(dsn: DsnComponents, tunnel?: string): string;
/**
 * Returns an object that can be used in request headers.
 * This is needed for node and the old /store endpoint in sentry
 */
export declare function getRequestHeaders(dsn: DsnComponents, clientName: string, clientVersion: string): {
    [key: string]: string;
};
/** Returns the url to the report dialog endpoint. */
export declare function getReportDialogEndpoint(dsnLike: DsnLike, dialogOptions: {
    [key: string]: any;
    user?: {
        name?: string;
        email?: string;
    };
}): string;
//# sourceMappingURL=api.d.ts.map