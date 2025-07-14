import { Client, SessionAggregates, SessionFlusherLike } from '@sentry/types';
type ReleaseHealthAttributes = {
    environment?: string;
    release: string;
};
/**
 * @inheritdoc
 */
export declare class SessionFlusher implements SessionFlusherLike {
    readonly flushTimeout: number;
    private _pendingAggregates;
    private _sessionAttrs;
    private _intervalId;
    private _isEnabled;
    private _client;
    constructor(client: Client, attrs: ReleaseHealthAttributes);
    /** Checks if `pendingAggregates` has entries, and if it does flushes them by calling `sendSession` */
    flush(): void;
    /** Massages the entries in `pendingAggregates` and returns aggregated sessions */
    getSessionAggregates(): SessionAggregates;
    /** JSDoc */
    close(): void;
    /**
     * Wrapper function for _incrementSessionStatusCount that checks if the instance of SessionFlusher is enabled then
     * fetches the session status of the request from `Scope.getRequestSession().status` on the scope and passes them to
     * `_incrementSessionStatusCount` along with the start date
     */
    incrementSessionStatusCount(): void;
    /**
     * Increments status bucket in pendingAggregates buffer (internal state) corresponding to status of
     * the session received
     */
    private _incrementSessionStatusCount;
}
export {};
//# sourceMappingURL=sessionflusher.d.ts.map
