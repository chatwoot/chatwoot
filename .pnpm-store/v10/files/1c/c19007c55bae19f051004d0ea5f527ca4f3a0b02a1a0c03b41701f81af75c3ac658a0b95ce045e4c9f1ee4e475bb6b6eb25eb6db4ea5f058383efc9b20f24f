import type { PostHog } from './posthog-core';
import { RequestResponse } from './types';
export declare class RateLimiter {
    instance: PostHog;
    serverLimits: Record<string, number>;
    captureEventsPerSecond: number;
    captureEventsBurstLimit: number;
    lastEventRateLimited: boolean;
    constructor(instance: PostHog);
    clientRateLimitContext(checkOnly?: boolean): {
        isRateLimited: boolean;
        remainingTokens: number;
    };
    isServerRateLimited(batchKey: string | undefined): boolean;
    checkForLimiting: (httpResponse: RequestResponse) => void;
}
