import type { eventWithTime } from '@rrweb/types';
import type { rrwebRecord } from './types/rrweb';
export declare class MutationThrottler {
    private readonly _rrweb;
    private readonly _options;
    private _loggedTracker;
    private _rateLimiter;
    constructor(_rrweb: rrwebRecord, _options?: {
        bucketSize?: number;
        refillRate?: number;
        onBlockedNode?: (id: number, node: Node | null) => void;
    });
    private _onNodeRateLimited;
    private _getNodeOrRelevantParent;
    private _getNode;
    private _numberOfChanges;
    throttleMutations: (event: eventWithTime) => eventWithTime | undefined;
}
