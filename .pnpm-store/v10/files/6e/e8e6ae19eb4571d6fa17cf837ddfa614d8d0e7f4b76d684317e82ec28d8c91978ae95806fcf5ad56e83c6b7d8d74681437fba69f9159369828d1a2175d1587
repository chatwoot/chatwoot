import { timestampInSeconds } from '@sentry/utils';
import { updateMetricSummaryOnActiveSpan } from '../utils/spanUtils.js';
import { DEFAULT_BROWSER_FLUSH_INTERVAL, SET_METRIC_TYPE } from './constants.js';
import { captureAggregateMetrics } from './envelope.js';
import { METRIC_MAP } from './instance.js';
import { sanitizeMetricKey, sanitizeTags, sanitizeUnit, getBucketKey } from './utils.js';

/**
 * A simple metrics aggregator that aggregates metrics in memory and flushes them periodically.
 * Default flush interval is 5 seconds.
 *
 * @experimental This API is experimental and might change in the future.
 */
class BrowserMetricsAggregator  {
  // TODO(@anonrig): Use FinalizationRegistry to have a proper way of flushing the buckets
  // when the aggregator is garbage collected.
  // Ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/FinalizationRegistry

   constructor(  _client) {this._client = _client;
    this._buckets = new Map();
    this._interval = setInterval(() => this.flush(), DEFAULT_BROWSER_FLUSH_INTERVAL);
  }

  /**
   * @inheritDoc
   */
   add(
    metricType,
    unsanitizedName,
    value,
    unsanitizedUnit = 'none',
    unsanitizedTags = {},
    maybeFloatTimestamp = timestampInSeconds(),
  ) {
    const timestamp = Math.floor(maybeFloatTimestamp);
    const name = sanitizeMetricKey(unsanitizedName);
    const tags = sanitizeTags(unsanitizedTags);
    const unit = sanitizeUnit(unsanitizedUnit );

    const bucketKey = getBucketKey(metricType, name, unit, tags);

    let bucketItem = this._buckets.get(bucketKey);
    // If this is a set metric, we need to calculate the delta from the previous weight.
    const previousWeight = bucketItem && metricType === SET_METRIC_TYPE ? bucketItem.metric.weight : 0;

    if (bucketItem) {
      bucketItem.metric.add(value);
      // TODO(abhi): Do we need this check?
      if (bucketItem.timestamp < timestamp) {
        bucketItem.timestamp = timestamp;
      }
    } else {
      bucketItem = {
        // @ts-expect-error we don't need to narrow down the type of value here, saves bundle size.
        metric: new METRIC_MAP[metricType](value),
        timestamp,
        metricType,
        name,
        unit,
        tags,
      };
      this._buckets.set(bucketKey, bucketItem);
    }

    // If value is a string, it's a set metric so calculate the delta from the previous weight.
    const val = typeof value === 'string' ? bucketItem.metric.weight - previousWeight : value;
    updateMetricSummaryOnActiveSpan(metricType, name, val, unit, unsanitizedTags, bucketKey);
  }

  /**
   * @inheritDoc
   */
   flush() {
    // short circuit if buckets are empty.
    if (this._buckets.size === 0) {
      return;
    }

    const metricBuckets = Array.from(this._buckets.values());
    captureAggregateMetrics(this._client, metricBuckets);

    this._buckets.clear();
  }

  /**
   * @inheritDoc
   */
   close() {
    clearInterval(this._interval);
    this.flush();
  }
}

export { BrowserMetricsAggregator };
//# sourceMappingURL=browser-aggregator.js.map
