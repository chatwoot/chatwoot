Object.defineProperty(exports, '__esModule', { value: true });

const utils$1 = require('@sentry/utils');
const spanUtils = require('../utils/spanUtils.js');
const constants = require('./constants.js');
const envelope = require('./envelope.js');
const instance = require('./instance.js');
const utils = require('./utils.js');

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
    this._interval = setInterval(() => this.flush(), constants.DEFAULT_BROWSER_FLUSH_INTERVAL);
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
    maybeFloatTimestamp = utils$1.timestampInSeconds(),
  ) {
    const timestamp = Math.floor(maybeFloatTimestamp);
    const name = utils.sanitizeMetricKey(unsanitizedName);
    const tags = utils.sanitizeTags(unsanitizedTags);
    const unit = utils.sanitizeUnit(unsanitizedUnit );

    const bucketKey = utils.getBucketKey(metricType, name, unit, tags);

    let bucketItem = this._buckets.get(bucketKey);
    // If this is a set metric, we need to calculate the delta from the previous weight.
    const previousWeight = bucketItem && metricType === constants.SET_METRIC_TYPE ? bucketItem.metric.weight : 0;

    if (bucketItem) {
      bucketItem.metric.add(value);
      // TODO(abhi): Do we need this check?
      if (bucketItem.timestamp < timestamp) {
        bucketItem.timestamp = timestamp;
      }
    } else {
      bucketItem = {
        // @ts-expect-error we don't need to narrow down the type of value here, saves bundle size.
        metric: new instance.METRIC_MAP[metricType](value),
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
    spanUtils.updateMetricSummaryOnActiveSpan(metricType, name, val, unit, unsanitizedTags, bucketKey);
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
    envelope.captureAggregateMetrics(this._client, metricBuckets);

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

exports.BrowserMetricsAggregator = BrowserMetricsAggregator;
//# sourceMappingURL=browser-aggregator.js.map
