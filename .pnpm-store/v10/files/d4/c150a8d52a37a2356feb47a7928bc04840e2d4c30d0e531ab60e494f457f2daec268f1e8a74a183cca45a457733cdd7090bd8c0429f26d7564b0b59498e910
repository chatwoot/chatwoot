Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const currentScopes = require('../currentScopes.js');
const debugBuild = require('../debug-build.js');
require('../tracing/errors.js');
const spanUtils = require('../utils/spanUtils.js');
const trace = require('../tracing/trace.js');
const handleCallbackErrors = require('../utils/handleCallbackErrors.js');
const constants = require('./constants.js');

/**
 * Gets the metrics aggregator for a given client.
 * @param client The client for which to get the metrics aggregator.
 * @param Aggregator Optional metrics aggregator class to use to create an aggregator if one does not exist.
 */
function getMetricsAggregatorForClient(
  client,
  Aggregator,
) {
  const globalMetricsAggregators = utils.getGlobalSingleton(
    'globalMetricsAggregators',
    () => new WeakMap(),
  );

  const aggregator = globalMetricsAggregators.get(client);
  if (aggregator) {
    return aggregator;
  }

  const newAggregator = new Aggregator(client);
  client.on('flush', () => newAggregator.flush());
  client.on('close', () => newAggregator.close());
  globalMetricsAggregators.set(client, newAggregator);

  return newAggregator;
}

function addToMetricsAggregator(
  Aggregator,
  metricType,
  name,
  value,
  data = {},
) {
  const client = data.client || currentScopes.getClient();

  if (!client) {
    return;
  }

  const span = spanUtils.getActiveSpan();
  const rootSpan = span ? spanUtils.getRootSpan(span) : undefined;
  const transactionName = rootSpan && spanUtils.spanToJSON(rootSpan).description;

  const { unit, tags, timestamp } = data;
  const { release, environment } = client.getOptions();
  const metricTags = {};
  if (release) {
    metricTags.release = release;
  }
  if (environment) {
    metricTags.environment = environment;
  }
  if (transactionName) {
    metricTags.transaction = transactionName;
  }

  debugBuild.DEBUG_BUILD && utils.logger.log(`Adding value of ${value} to ${metricType} metric ${name}`);

  const aggregator = getMetricsAggregatorForClient(client, Aggregator);
  aggregator.add(metricType, name, value, unit, { ...metricTags, ...tags }, timestamp);
}

/**
 * Adds a value to a counter metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function increment(aggregator, name, value = 1, data) {
  addToMetricsAggregator(aggregator, constants.COUNTER_METRIC_TYPE, name, ensureNumber(value), data);
}

/**
 * Adds a value to a distribution metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function distribution(aggregator, name, value, data) {
  addToMetricsAggregator(aggregator, constants.DISTRIBUTION_METRIC_TYPE, name, ensureNumber(value), data);
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
  aggregator,
  name,
  value,
  unit = 'second',
  data,
) {
  // callback form
  if (typeof value === 'function') {
    const startTime = utils.timestampInSeconds();

    return trace.startSpanManual(
      {
        op: 'metrics.timing',
        name,
        startTime,
        onlyIfParent: true,
      },
      span => {
        return handleCallbackErrors.handleCallbackErrors(
          () => value(),
          () => {
            // no special error handling necessary
          },
          () => {
            const endTime = utils.timestampInSeconds();
            const timeDiff = endTime - startTime;
            distribution(aggregator, name, timeDiff, { ...data, unit: 'second' });
            span.end(endTime);
          },
        );
      },
    );
  }

  // value form
  distribution(aggregator, name, value, { ...data, unit });
}

/**
 * Adds a value to a set metric. Value must be a string or integer.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function set(aggregator, name, value, data) {
  addToMetricsAggregator(aggregator, constants.SET_METRIC_TYPE, name, value, data);
}

/**
 * Adds a value to a gauge metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
function gauge(aggregator, name, value, data) {
  addToMetricsAggregator(aggregator, constants.GAUGE_METRIC_TYPE, name, ensureNumber(value), data);
}

const metrics = {
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

// Although this is typed to be a number, we try to handle strings as well here
function ensureNumber(number) {
  return typeof number === 'string' ? parseInt(number) : number;
}

exports.metrics = metrics;
//# sourceMappingURL=exports.js.map
