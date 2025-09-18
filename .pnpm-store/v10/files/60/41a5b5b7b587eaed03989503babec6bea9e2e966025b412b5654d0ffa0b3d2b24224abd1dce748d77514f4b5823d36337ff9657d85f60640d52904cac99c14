import { DsnComponents, DsnLike, SdkInfo } from '@sentry/types';
/**
 * Returns the envelope endpoint URL with auth in the query string.
 *
 * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
 */
export declare function getEnvelopeEndpointWithUrlEncodedAuth(dsn: DsnComponents, tunnel?: string, sdkInfo?: SdkInfo): string;
/** Returns the url to the report dialog endpoint. */
export declare function getReportDialogEndpoint(dsnLike: DsnLike, dialogOptions: {
    [key: string]: any;
    user?: {
        name?: string;
        email?: string;
    };
}): string;
//# sourceMappingURL=api.d.ts.map
