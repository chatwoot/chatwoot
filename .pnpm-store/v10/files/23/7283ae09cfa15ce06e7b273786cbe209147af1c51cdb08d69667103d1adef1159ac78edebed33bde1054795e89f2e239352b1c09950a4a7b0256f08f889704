Object.defineProperty(exports, '__esModule', { value: true });

const utils = require('@sentry/utils');
const utils$1 = require('./utils.js');

/**
 * Captures aggregated metrics to the supplied client.
 */
function captureAggregateMetrics(client, metricBucketItems) {
  utils.logger.log(`Flushing aggregated metrics, number of metrics: ${metricBucketItems.length}`);
  const dsn = client.getDsn();
  const metadata = client.getSdkMetadata();
  const tunnel = client.getOptions().tunnel;

  const metricsEnvelope = createMetricEnvelope(metricBucketItems, dsn, metadata, tunnel);

  // sendEnvelope should not throw
  // eslint-disable-next-line @typescript-eslint/no-floating-promises
  client.sendEnvelope(metricsEnvelope);
}

/**
 * Create envelope from a metric aggregate.
 */
function createMetricEnvelope(
  metricBucketItems,
  dsn,
  metadata,
  tunnel,
) {
  const headers = {
    sent_at: new Date().toISOString(),
  };

  if (metadata && metadata.sdk) {
    headers.sdk = {
      name: metadata.sdk.name,
      version: metadata.sdk.version,
    };
  }

  if (!!tunnel && dsn) {
    headers.dsn = utils.dsnToString(dsn);
  }

  const item = createMetricEnvelopeItem(metricBucketItems);
  return utils.createEnvelope(headers, [item]);
}

function createMetricEnvelopeItem(metricBucketItems) {
  const payload = utils$1.serializeMetricBuckets(metricBucketItems);
  const metricHeaders = {
    type: 'statsd',
    length: payload.length,
  };
  return [metricHeaders, payload];
}

exports.captureAggregateMetrics = captureAggregateMetrics;
exports.createMetricEnvelope = createMetricEnvelope;
//# sourceMappingURL=envelope.js.map
