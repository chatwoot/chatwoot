import { MetricInstance } from '@sentry/types';
/**
 * A metric instance representing a counter.
 */
export declare class CounterMetric implements MetricInstance {
    private _value;
    constructor(_value: number);
    /*@inheritDoc */
    readonly weight: number;
    /** @inheritdoc */
    add(value: number): void;
    /** @inheritdoc */
    toString(): string;
}
/**
 * A metric instance representing a gauge.
 */
export declare class GaugeMetric implements MetricInstance {
    private _last;
    private _min;
    private _max;
    private _sum;
    private _count;
    constructor(value: number);
    /*@inheritDoc */
    readonly weight: number;
    /** @inheritdoc */
    add(value: number): void;
    /** @inheritdoc */
    toString(): string;
}
/**
 * A metric instance representing a distribution.
 */
export declare class DistributionMetric implements MetricInstance {
    private _value;
    constructor(first: number);
    /*@inheritDoc */
    readonly weight: number;
    /** @inheritdoc */
    add(value: number): void;
    /** @inheritdoc */
    toString(): string;
}
/**
 * A metric instance representing a set.
 */
export declare class SetMetric implements MetricInstance {
    first: number | string;
    private _value;
    constructor(first: number | string);
    /*@inheritDoc */
    readonly weight: number;
    /** @inheritdoc */
    add(value: number | string): void;
    /** @inheritdoc */
    toString(): string;
}
export declare const METRIC_MAP: {
    c: typeof CounterMetric;
    g: typeof GaugeMetric;
    d: typeof DistributionMetric;
    s: typeof SetMetric;
};
//# sourceMappingURL=instance.d.ts.map
