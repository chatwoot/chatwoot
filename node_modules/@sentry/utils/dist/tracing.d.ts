import { TraceparentData } from '@sentry/types';
export declare const TRACEPARENT_REGEXP: RegExp;
/**
 * Extract transaction context data from a `sentry-trace` header.
 *
 * @param traceparent Traceparent string
 *
 * @returns Object containing data from the header, or undefined if traceparent string is malformed
 */
export declare function extractTraceparentData(traceparent: string): TraceparentData | undefined;
//# sourceMappingURL=tracing.d.ts.map