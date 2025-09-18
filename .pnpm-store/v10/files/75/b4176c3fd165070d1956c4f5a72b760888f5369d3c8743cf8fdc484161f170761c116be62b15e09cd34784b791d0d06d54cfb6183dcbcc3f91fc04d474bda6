import type { Client } from './client';
import type { DurationUnit, MeasurementUnit } from './measurement';
import type { Primitive } from './misc';
export interface MetricData {
    unit?: MeasurementUnit;
    tags?: Record<string, Primitive>;
    timestamp?: number;
    client?: Client;
}
/**
 * An abstract definition of the minimum required API
 * for a metric instance.
 */
export interface MetricInstance {
    /**
     * Returns the weight of the metric.
     */
    weight: number;
    /**
     * Adds a value to a metric.
     */
    add(value: number | string): void;
    /**
     * Serializes the metric into a statsd format string.
     */
    toString(): string;
}
export interface MetricBucketItem {
    metric: MetricInstance;
    timestamp: number;
    metricType: 'c' | 'g' | 's' | 'd';
    name: string;
    unit: MeasurementUnit;
    tags: Record<string, string>;
}
/**
 * A metrics aggregator that aggregates metrics in memory and flushes them periodically.
 */
export interface MetricsAggregator {
    /**
     * Add a metric to the aggregator.
     */
    add(metricType: 'c' | 'g' | 's' | 'd', name: string, value: number | string, unit?: MeasurementUnit, tags?: Record<string, Primitive>, timestamp?: number): void;
    /**
     * Flushes the current metrics to the transport via the transport.
     */
    flush(): void;
    /**
     * Shuts down metrics aggregator and clears all metrics.
     */
    close(): void;
    /**
     * Returns a string representation of the aggregator.
     */
    toString(): string;
}
export interface Metrics {
    /**
     * Adds a value to a counter metric
     *
     * @experimental This API is experimental and might have breaking changes in the future.
     */
    increment(name: string, value?: number, data?: MetricData): void;
    /**
     * Adds a value to a distribution metric
     *
     * @experimental This API is experimental and might have breaking changes in the future.
     */
    distribution(name: string, value: number, data?: MetricData): void;
    /**
     * Adds a value to a set metric. Value must be a string or integer.
     *
     * @experimental This API is experimental and might have breaking changes in the future.
     */
    set(name: string, value: number | string, data?: MetricData): void;
    /**
     * Adds a value to a gauge metric
     *
     * @experimental This API is experimental and might have breaking changes in the future.
     */
    gauge(name: string, value: number, data?: MetricData): void;
    /**
     * Adds a timing metric.
     * The metric is added as a distribution metric.
     *
     * You can either directly capture a numeric `value`, or wrap a callback function in `timing`.
     * In the latter case, the duration of the callback execution will be captured as a span & a metric.
     *
     * @experimental This API is experimental and might have breaking changes in the future.
     */
    timing(name: string, value: number, unit?: DurationUnit, data?: Omit<MetricData, 'unit'>): void;
    timing<T>(name: string, callback: () => T, unit?: DurationUnit, data?: Omit<MetricData, 'unit'>): T;
}
//# sourceMappingURL=metrics.d.ts.map