import { QueuedRequestWithOptions, RequestQueueConfig } from './types';
export declare const DEFAULT_FLUSH_INTERVAL_MS = 3000;
export declare class RequestQueue {
    private _isPaused;
    private _queue;
    private _flushTimeout?;
    private _flushTimeoutMs;
    private _sendRequest;
    constructor(sendRequest: (req: QueuedRequestWithOptions) => void, config?: RequestQueueConfig);
    enqueue(req: QueuedRequestWithOptions): void;
    unload(): void;
    enable(): void;
    private _setFlushTimeout;
    private _clearFlushTimeout;
    private _formatQueue;
}
