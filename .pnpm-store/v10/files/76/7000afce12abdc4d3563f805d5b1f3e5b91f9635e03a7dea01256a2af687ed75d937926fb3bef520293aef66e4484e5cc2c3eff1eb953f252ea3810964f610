import { dropUndefinedKeys } from '@sentry/utils';

/**
 * key: bucketKey
 * value: [exportKey, MetricSummary]
 */

const METRICS_SPAN_FIELD = '_sentryMetrics';

/**
 * Fetches the metric summary if it exists for the passed span
 */
function getMetricSummaryJsonForSpan(span) {
  const storage = (span )[METRICS_SPAN_FIELD];

  if (!storage) {
    return undefined;
  }
  const output = {};

  for (const [, [exportKey, summary]] of storage) {
    const arr = output[exportKey] || (output[exportKey] = []);
    arr.push(dropUndefinedKeys(summary));
  }

  return output;
}

/**
 * Updates the metric summary on a span.
 */
function updateMetricSummaryOnSpan(
  span,
  metricType,
  sanitizedName,
  value,
  unit,
  tags,
  bucketKey,
) {
  const existingStorage = (span )[METRICS_SPAN_FIELD];
  const storage =
    existingStorage ||
    ((span )[METRICS_SPAN_FIELD] = new Map());

  const exportKey = `${metricType}:${sanitizedName}@${unit}`;
  const bucketItem = storage.get(bucketKey);

  if (bucketItem) {
    const [, summary] = bucketItem;
    storage.set(bucketKey, [
      exportKey,
      {
        min: Math.min(summary.min, value),
        max: Math.max(summary.max, value),
        count: (summary.count += 1),
        sum: (summary.sum += value),
        tags: summary.tags,
      },
    ]);
  } else {
    storage.set(bucketKey, [
      exportKey,
      {
        min: value,
        max: value,
        count: 1,
        sum: value,
        tags,
      },
    ]);
  }
}

export { getMetricSummaryJsonForSpan, updateMetricSummaryOnSpan };
//# sourceMappingURL=metric-summary.js.map
