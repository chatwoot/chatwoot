Object.defineProperty(exports, '__esModule', { value: true });

const aggregator = require('./aggregator.js');
const exports$1 = require('./exports.js');

/**
 * Adds a value to a counter metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function increment(name, value = 1, data) {
  exports$1.metrics.increment(aggregator.MetricsAggregator, name, value, data);
}

/**
 * Adds a value to a distribution metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function distribution(name, value, data) {
  exports$1.metrics.distribution(aggregator.MetricsAggregator, name, value, data);
}

/**
 * Adds a value to a set metric. Value must be a string or integer.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function set(name, value, data) {
  exports$1.metrics.set(aggregator.MetricsAggregator, name, value, data);
}

/**
 * Adds a value to a gauge metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function gauge(name, value, data) {
  exports$1.metrics.gauge(aggregator.MetricsAggregator, name, value, data);
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
  return exports$1.metrics.timing(aggregator.MetricsAggregator, name, value, unit, data);
}

/**
 * Returns the metrics aggregator for a given client.
 */
function getMetricsAggregatorForClient(client) {
  return exports$1.metrics.getMetricsAggregatorForClient(client, aggregator.MetricsAggregator);
}

const metricsDefault

 = {
  increment,
  distribution,
  set,
  gauge,
  timing,
  /**
   * @ignore This is for internal use only.
   */
  getMetricsAggregatorForClient,
};

exports.metricsDefault = metricsDefault;
//# sourceMappingURL=exports-default.js.map
