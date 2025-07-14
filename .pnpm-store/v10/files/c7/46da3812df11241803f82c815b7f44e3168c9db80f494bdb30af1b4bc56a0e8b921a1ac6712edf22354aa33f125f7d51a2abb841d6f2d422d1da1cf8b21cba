declare type CompactMetricType = 'g' | 'c';
export declare type CoreMetricType = 'gauge' | 'counter';
export interface CoreMetric {
    metric: string;
    value: number;
    type: CoreMetricType;
    tags: string[];
    timestamp: number;
}
export interface CompactMetric {
    m: string;
    v: number;
    k: CompactMetricType;
    t: string[];
    e: number;
}
export declare abstract class CoreStats {
    metrics: CoreMetric[];
    increment(metric: string, by?: number, tags?: string[]): void;
    gauge(metric: string, value: number, tags?: string[]): void;
    flush(): void;
    /**
     * compact keys for smaller payload
     */
    serialize(): CompactMetric[];
}
export declare class NullStats extends CoreStats {
    gauge(..._args: Parameters<CoreStats['gauge']>): void;
    increment(..._args: Parameters<CoreStats['increment']>): void;
    flush(..._args: Parameters<CoreStats['flush']>): void;
    serialize(..._args: Parameters<CoreStats['serialize']>): never[];
}
export {};
//# sourceMappingURL=index.d.ts.map