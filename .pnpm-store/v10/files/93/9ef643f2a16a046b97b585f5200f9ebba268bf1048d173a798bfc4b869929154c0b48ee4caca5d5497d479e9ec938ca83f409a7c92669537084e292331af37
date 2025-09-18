import type { Client, MeasurementUnit, MetricsAggregator as MetricsAggregatorBase, Primitive } from '@sentry/types';
import type { MetricType } from './types';
/**
 * A metrics aggregator that aggregates metrics in memory and flushes them periodically.
 */
export declare class MetricsAggregator implements MetricsAggregatorBase {
    private readonly _client;
    private _buckets;
    private _bucketsTotalWeight;
    private readonly _interval;
    private readonly _flushShift;
    private _forceFlush;
    constructor(_client: Client);
    /**
     * @inheritDoc
     */
    add(metricType: MetricType, unsanitizedName: string, value: number | string, unsanitizedUnit?: MeasurementUnit, unsanitizedTags?: Record<string, Primitive>, maybeFloatTimestamp?: number): void;
    /**
     * Flushes the current metrics to the transport via the transport.
     */
    flush(): void;
    /**
     * Shuts down metrics aggregator and clears all metrics.
     */
    close(): void;
    /**
     * Flushes the buckets according to the internal state of the aggregator.
     * If it is a force flush, which happens on shutdown, it will flush all buckets.
     * Otherwise, it will only flush buckets that are older than the flush interval,
     * and according to the flush shift.
     *
     * This function mutates `_forceFlush` and `_bucketsTotalWeight` properties.
     */
    private _flush;
    /**
     * Only captures a subset of the buckets passed to this function.
     * @param flushedBuckets
     */
    private _captureMetrics;
}
//# sourceMappingURL=aggregator.d.ts.map