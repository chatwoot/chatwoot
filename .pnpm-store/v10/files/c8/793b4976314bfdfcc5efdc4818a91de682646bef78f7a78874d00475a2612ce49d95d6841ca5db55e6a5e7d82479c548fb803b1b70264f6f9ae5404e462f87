const COUNTER_METRIC_TYPE = 'c' ;
const GAUGE_METRIC_TYPE = 'g' ;
const SET_METRIC_TYPE = 's' ;
const DISTRIBUTION_METRIC_TYPE = 'd' ;

/**
 * This does not match spec in https://develop.sentry.dev/sdk/metrics
 * but was chosen to optimize for the most common case in browser environments.
 */
const DEFAULT_BROWSER_FLUSH_INTERVAL = 5000;

/**
 * SDKs are required to bucket into 10 second intervals (rollup in seconds)
 * which is the current lower bound of metric accuracy.
 */
const DEFAULT_FLUSH_INTERVAL = 10000;

/**
 * The maximum number of metrics that should be stored in memory.
 */
const MAX_WEIGHT = 10000;

export { COUNTER_METRIC_TYPE, DEFAULT_BROWSER_FLUSH_INTERVAL, DEFAULT_FLUSH_INTERVAL, DISTRIBUTION_METRIC_TYPE, GAUGE_METRIC_TYPE, MAX_WEIGHT, SET_METRIC_TYPE };
//# sourceMappingURL=constants.js.map
