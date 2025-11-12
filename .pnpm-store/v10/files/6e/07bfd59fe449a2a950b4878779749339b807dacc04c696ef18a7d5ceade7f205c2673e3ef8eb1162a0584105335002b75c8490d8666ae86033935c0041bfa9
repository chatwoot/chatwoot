import { metrics as metrics$1, BrowserMetricsAggregator } from '@sentry/core';

/**
 * Adds a value to a counter metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function increment(name, value = 1, data) {
  metrics$1.increment(BrowserMetricsAggregator, name, value, data);
}

/**
 * Adds a value to a distribution metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function distribution(name, value, data) {
  metrics$1.distribution(BrowserMetricsAggregator, name, value, data);
}

/**
 * Adds a value to a set metric. Value must be a string or integer.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function set(name, value, data) {
  metrics$1.set(BrowserMetricsAggregator, name, value, data);
}

/**
 * Adds a value to a gauge metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function gauge(name, value, data) {
  metrics$1.gauge(BrowserMetricsAggregator, name, value, data);
}

/**
 * Adds a timing metric.
 * The metric is added as a distribution metric.
 *
 * You can either directly capture a numeric `value`, or wrap a callback function in `timing`.
 * In the latter case, the duration of the callback execution will be captured as a span & a metric.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */

function timing(
  name,
  value,
  unit = 'second',
  data,
) {
  return metrics$1.timing(BrowserMetricsAggregator, name, value, unit, data);
}

const metrics = {
  increment,
  distribution,
  set,
  gauge,
  timing,
};

export { metrics };
//# sourceMappingURL=metrics.js.map
