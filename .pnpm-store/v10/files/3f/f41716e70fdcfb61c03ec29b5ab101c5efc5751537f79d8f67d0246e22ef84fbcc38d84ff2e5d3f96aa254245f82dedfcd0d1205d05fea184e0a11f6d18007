export interface MetricsOptions {
    host?: string;
    sampleRate?: number;
    flushTimer?: number;
    maxQueueSize?: number;
}
/**
 * Type expected by the segment metrics API endpoint
 */
type RemoteMetric = {
    type: 'Counter';
    metric: string;
    value: 1;
    tags: {
        library: string;
        library_version: string;
        [key: string]: string;
    };
};
export declare class RemoteMetrics {
    private host;
    private flushTimer;
    private maxQueueSize;
    sampleRate: number;
    queue: RemoteMetric[];
    constructor(options?: MetricsOptions);
    increment(metric: string, tags: string[]): void;
    flush(): Promise<void>;
    private send;
}
export {};
//# sourceMappingURL=remote-metrics.d.ts.map