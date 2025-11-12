import { Logger } from '../types';
export declare class BucketedRateLimiter<T extends string | number> {
    private readonly _options;
    private _bucketSize;
    private _refillRate;
    private _refillInterval;
    private _onBucketRateLimited?;
    private _buckets;
    constructor(_options: {
        bucketSize: number;
        refillRate: number;
        refillInterval: number;
        _logger: Logger;
        _onBucketRateLimited?: (key: T) => void;
    });
    private _refillBuckets;
    private _getBucket;
    private _setBucket;
    consumeRateLimit: (key: T) => boolean;
}
//# sourceMappingURL=bucketed-rate-limiter.d.ts.map