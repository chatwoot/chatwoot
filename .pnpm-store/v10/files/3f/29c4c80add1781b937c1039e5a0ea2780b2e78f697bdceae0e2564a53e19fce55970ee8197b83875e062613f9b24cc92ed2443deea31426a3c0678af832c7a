import { timestampInSeconds } from '@sentry/utils';
import { updateMetricSummaryOnActiveSpan } from '../utils/spanUtils.js';
import { DEFAULT_FLUSH_INTERVAL, SET_METRIC_TYPE, MAX_WEIGHT } from './constants.js';
import { captureAggregateMetrics } from './envelope.js';
import { METRIC_MAP } from './instance.js';
import { sanitizeMetricKey, sanitizeTags, sanitizeUnit, getBucketKey } from './utils.js';

/**
 * A metrics aggregator that aggregates metrics in memory and flushes them periodically.
 */
class MetricsAggregator  {
  // TODO(@anonrig): Use FinalizationRegistry to have a proper way of flushing the buckets
  // when the aggregator is garbage collected.
  // Ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/FinalizationRegistry

  // Different metrics have different weights. We use this to limit the number of metrics
  // that we store in memory.

  // Cast to any so that it can use Node.js timeout
  // eslint-disable-next-line @typescript-eslint/no-explicit-any

  // SDKs are required to shift the flush interval by random() * rollup_in_seconds.
  // That shift is determined once per startup to create jittering.

  // An SDK is required to perform force flushing ahead of scheduled time if the memory
  // pressure is too high. There is no rule for this other than that SDKs should be tracking
  // abstract aggregation complexity (eg: a counter only carries a single float, whereas a
  // distribution is a float per emission).
  //
  // Force flush is used on either shutdown, flush() or when we exceed the max weight.

   constructor(  _client) {this._client = _client;
    this._buckets = new Map();
    this._bucketsTotalWeight = 0;

    this._interval = setInterval(() => this._flush(), DEFAULT_FLUSH_INTERVAL) ;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    if (this._interval.unref) {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      this._interval.unref();
    }

    this._flushShift = Math.floor((Math.random() * DEFAULT_FLUSH_INTERVAL) / 1000);
    this._forceFlush = false;
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

    // We need to keep track of the total weight of the buckets so that we can
    // flush them when we exceed the max weight.
    this._bucketsTotalWeight += bucketItem.metric.weight;

    if (this._bucketsTotalWeight >= MAX_WEIGHT) {
      this.flush();
    }
  }

  /**
   * Flushes the current metrics to the transport via the transport.
   */
   flush() {
    this._forceFlush = true;
    this._flush();
  }

  /**
   * Shuts down metrics aggregator and clears all metrics.
   */
   close() {
    this._forceFlush = true;
    clearInterval(this._interval);
    this._flush();
  }

  /**
   * Flushes the buckets according to the internal state of the aggregator.
   * If it is a force flush, which happens on shutdown, it will flush all buckets.
   * Otherwise, it will only flush buckets that are older than the flush interval,
   * and according to the flush shift.
   *
   * This function mutates `_forceFlush` and `_bucketsTotalWeight` properties.
   */
   _flush() {
    // TODO(@anonrig): Add Atomics for locking to avoid having force flush and regular flush
    // running at the same time.
    // Ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Atomics

    // This path eliminates the need for checking for timestamps since we're forcing a flush.
    // Remember to reset the flag, or it will always flush all metrics.
    if (this._forceFlush) {
      this._forceFlush = false;
      this._bucketsTotalWeight = 0;
      this._captureMetrics(this._buckets);
      this._buckets.clear();
      return;
    }
    const cutoffSeconds = Math.floor(timestampInSeconds()) - DEFAULT_FLUSH_INTERVAL / 1000 - this._flushShift;
    // TODO(@anonrig): Optimization opportunity.
    // Convert this map to an array and store key in the bucketItem.
    const flushedBuckets = new Map();
    for (const [key, bucket] of this._buckets) {
      if (bucket.timestamp <= cutoffSeconds) {
        flushedBuckets.set(key, bucket);
        this._bucketsTotalWeight -= bucket.metric.weight;
      }
    }

    for (const [key] of flushedBuckets) {
      this._buckets.delete(key);
    }

    this._captureMetrics(flushedBuckets);
  }

  /**
   * Only captures a subset of the buckets passed to this function.
   * @param flushedBuckets
   */
   _captureMetrics(flushedBuckets) {
    if (flushedBuckets.size > 0) {
      // TODO(@anonrig): Optimization opportunity.
      // This copy operation can be avoided if we store the key in the bucketItem.
      const buckets = Array.from(flushedBuckets).map(([, bucketItem]) => bucketItem);
      captureAggregateMetrics(this._client, buckets);
    }
  }
}

export { MetricsAggregator };
//# sourceMappingURL=aggregator.js.map
