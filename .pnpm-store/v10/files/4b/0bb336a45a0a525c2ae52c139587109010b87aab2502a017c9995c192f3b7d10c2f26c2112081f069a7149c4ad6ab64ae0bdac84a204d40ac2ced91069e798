import { RetriableRequestWithOptions } from './types';
import { PostHog } from './posthog-core';
/**
 * Generates a jitter-ed exponential backoff delay in milliseconds
 *
 * The base value is 6 seconds, which is doubled with each retry
 * up to the maximum of 30 minutes
 *
 * Each value then has +/- 50% jitter
 *
 * Giving a range of 6 seconds up to 45 minutes
 */
export declare function pickNextRetryDelay(retriesPerformedSoFar: number): number;
export declare class RetryQueue {
    private _instance;
    private _isPolling;
    private _poller;
    private _pollIntervalMs;
    private _queue;
    private _areWeOnline;
    constructor(_instance: PostHog);
    get length(): number;
    retriableRequest({ retriesPerformedSoFar, ...options }: RetriableRequestWithOptions): void;
    private _enqueue;
    private _poll;
    private _flush;
    unload(): void;
}
