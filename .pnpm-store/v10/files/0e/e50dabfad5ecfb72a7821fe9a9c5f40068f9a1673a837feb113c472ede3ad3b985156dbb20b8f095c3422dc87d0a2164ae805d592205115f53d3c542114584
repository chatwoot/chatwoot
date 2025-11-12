import { Client, DurationUnit, MetricData, MetricsAggregator as MetricsAggregatorInterface } from '@sentry/types';
type MetricsAggregatorConstructor = {
    new (client: Client): MetricsAggregatorInterface;
};
/**
 * Gets the metrics aggregator for a given client.
 * @param client The client for which to get the metrics aggregator.
 * @param Aggregator Optional metrics aggregator class to use to create an aggregator if one does not exist.
 */
declare function getMetricsAggregatorForClient(client: Client, Aggregator: MetricsAggregatorConstructor): MetricsAggregatorInterface;
/**
 * Adds a value to a counter metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
declare function increment(aggregator: MetricsAggregatorConstructor, name: string, value?: number, data?: MetricData): void;
/**
 * Adds a value to a distribution metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
declare function distribution(aggregator: MetricsAggregatorConstructor, name: string, value: number, data?: MetricData): void;
/**
 * Adds a timing metric.
 * The metric is added as a distribution metric.
 *
 * You can either directly capture a numeric `value`, or wrap a callback function in `timing`.
 * In the latter case, the duration of the callback execution will be captured as a span & a metric.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
declare function timing<T = void>(aggregator: MetricsAggregatorConstructor, name: string, value: number | (() => T), unit?: DurationUnit, data?: Pick<MetricData, Exclude<keyof MetricData, 'unit'>>): T | void;
/**
 * Adds a value to a set metric. Value must be a string or integer.
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
declare function set(aggregator: MetricsAggregatorConstructor, name: string, value: number | string, data?: MetricData): void;
/**
 * Adds a value to a gauge metric
 *
 * @experimental This API is experimental and might have breaking changes in the future.
 */
declare function gauge(aggregator: MetricsAggregatorConstructor, name: string, value: number, data?: MetricData): void;
export declare const metrics: {
    increment: typeof increment;
    distribution: typeof distribution;
    set: typeof set;
    gauge: typeof gauge;
    timing: typeof timing;
    /**
     * @ignore This is for internal use only.
     */
    getMetricsAggregatorForClient: typeof getMetricsAggregatorForClient;
};
export {};
//# sourceMappingURL=exports.d.ts.map
