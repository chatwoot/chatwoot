export declare type EventStatus = 
/** The status could not be determined. */
'unknown'
/** The event was skipped due to configuration or callbacks. */
 | 'skipped'
/** The event was sent to Sentry successfully. */
 | 'rate_limit'
/** The client is currently rate limited and will try again later. */
 | 'invalid'
/** The event could not be processed. */
 | 'failed'
/** A server-side error occurred during submission. */
 | 'success';
//# sourceMappingURL=eventstatus.d.ts.map