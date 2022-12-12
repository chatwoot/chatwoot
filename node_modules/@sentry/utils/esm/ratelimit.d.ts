export declare type RateLimits = Record<string, number>;
export declare const DEFAULT_RETRY_AFTER: number;
/**
 * Extracts Retry-After value from the request header or returns default value
 * @param header string representation of 'Retry-After' header
 * @param now current unix timestamp
 *
 */
export declare function parseRetryAfterHeader(header: string, now?: number): number;
/**
 * Gets the time that given category is disabled until for rate limiting
 */
export declare function disabledUntil(limits: RateLimits, category: string): number;
/**
 * Checks if a category is rate limited
 */
export declare function isRateLimited(limits: RateLimits, category: string, now?: number): boolean;
/**
 * Update ratelimits from incoming headers.
 * Returns true if headers contains a non-empty rate limiting header.
 */
export declare function updateRateLimits(limits: RateLimits, headers: Record<string, string | null | undefined>, now?: number): RateLimits;
//# sourceMappingURL=ratelimit.d.ts.map