import type { Client, MeasurementUnit, MetricsAggregator, Primitive } from '@sentry/types';
import type { MetricType } from './types';
/**
 * A simple metrics aggregator that aggregates metrics in memory and flushes them periodically.
 * Default flush interval is 5 seconds.
 *
 * @experimental This API is experimental and might change in the future.
 */
export declare class BrowserMetricsAggregator implements MetricsAggregator {
    private readonly _client;
    private _buckets;
    private readonly _interval;
    constructor(_client: Client);
    /**
     * @inheritDoc
     */
    add(metricType: MetricType, unsanitizedName: string, value: number | string, unsanitizedUnit?: MeasurementUnit | undefined, unsanitizedTags?: Record<string, Primitive> | undefined, maybeFloatTimestamp?: number | undefined): void;
    /**
     * @inheritDoc
     */
    flush(): void;
    /**
     * @inheritDoc
     */
    close(): void;
}
//# sourceMappingURL=browser-aggregator.d.ts.map