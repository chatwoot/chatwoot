import { MeasurementUnit, MetricBucketItem, Primitive } from '@sentry/types';
import { MetricType } from './types';
/**
 * Generate bucket key from metric properties.
 */
export declare function getBucketKey(metricType: MetricType, name: string, unit: MeasurementUnit, tags: Record<string, string>): string;
/**
 * Simple hash function for strings.
 */
export declare function simpleHash(s: string): number;
/**
 * Serialize metrics buckets into a string based on statsd format.
 *
 * Example of format:
 * metric.name@second:1:1.2|d|#a:value,b:anothervalue|T12345677
 * Segments:
 * name: metric.name
 * unit: second
 * value: [1, 1.2]
 * type of metric: d (distribution)
 * tags: { a: value, b: anothervalue }
 * timestamp: 12345677
 */
export declare function serializeMetricBuckets(metricBucketItems: MetricBucketItem[]): string;
/**
 * Sanitizes units
 *
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
export declare function sanitizeUnit(unit: string): string;
/**
 * Sanitizes metric keys
 *
 * These Regex's are straight from the normalisation docs:
 * https://develop.sentry.dev/sdk/metrics/#normalization
 */
export declare function sanitizeMetricKey(key: string): string;
/**
 * Sanitizes tags.
 */
export declare function sanitizeTags(unsanitizedTags: Record<string, Primitive>): Record<string, string>;
//# sourceMappingURL=utils.d.ts.map
