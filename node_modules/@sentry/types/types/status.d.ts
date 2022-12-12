/** JSDoc
 * @deprecated Use string literals - if you require type casting, cast to EventStatus type
 */
export declare enum Status {
    /** The status could not be determined. */
    Unknown = "unknown",
    /** The event was skipped due to configuration or callbacks. */
    Skipped = "skipped",
    /** The event was sent to Sentry successfully. */
    Success = "success",
    /** The client is currently rate limited and will try again later. */
    RateLimit = "rate_limit",
    /** The event could not be processed. */
    Invalid = "invalid",
    /** A server-side error occurred during submission. */
    Failed = "failed"
}
//# sourceMappingURL=status.d.ts.map