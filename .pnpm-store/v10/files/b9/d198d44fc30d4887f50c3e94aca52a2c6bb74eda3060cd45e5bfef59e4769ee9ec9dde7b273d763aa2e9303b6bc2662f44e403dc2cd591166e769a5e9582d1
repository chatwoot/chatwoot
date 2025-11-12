import { logger, dsnToString, createEnvelope } from '@sentry/utils';
import { serializeMetricBuckets } from './utils.js';

/**
 * Captures aggregated metrics to the supplied client.
 */
function captureAggregateMetrics(client, metricBucketItems) {
  logger.log(`Flushing aggregated metrics, number of metrics: ${metricBucketItems.length}`);
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
    headers.dsn = dsnToString(dsn);
  }

  const item = createMetricEnvelopeItem(metricBucketItems);
  return createEnvelope(headers, [item]);
}

function createMetricEnvelopeItem(metricBucketItems) {
  const payload = serializeMetricBuckets(metricBucketItems);
  const metricHeaders = {
    type: 'statsd',
    length: payload.length,
  };
  return [metricHeaders, payload];
}

export { captureAggregateMetrics, createMetricEnvelope };
//# sourceMappingURL=envelope.js.map
