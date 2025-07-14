import { ReplayRecordingData } from '@sentry/types';
import { AddEventResult, EventBuffer, EventBufferType, RecordingEvent } from '../types';
/**
 * Event buffer that uses a web worker to compress events.
 * Exported only for testing.
 */
export declare class EventBufferCompressionWorker implements EventBuffer {
    /** @inheritdoc */
    hasCheckout: boolean;
    private _worker;
    private _earliestTimestamp;
    private _totalSize;
    constructor(worker: Worker);
    /*@inheritdoc */
    readonly hasEvents: boolean;
    /*@inheritdoc */
    readonly type: EventBufferType;
    /**
     * Ensure the worker is ready (or not).
     * This will either resolve when the worker is ready, or reject if an error occured.
     */
    ensureReady(): Promise<void>;
    /**
     * Destroy the event buffer.
     */
    destroy(): void;
    /**
     * Add an event to the event buffer.
     *
     * Returns true if event was successfuly received and processed by worker.
     */
    addEvent(event: RecordingEvent): Promise<AddEventResult>;
    /**
     * Finish the event buffer and return the compressed data.
     */
    finish(): Promise<ReplayRecordingData>;
    /** @inheritdoc */
    clear(): void;
    /** @inheritdoc */
    getEarliestTimestamp(): number | null;
    /**
     * Send the event to the worker.
     */
    private _sendEventToWorker;
    /**
     * Finish the request and return the compressed data from the worker.
     */
    private _finishRequest;
}
//# sourceMappingURL=EventBufferCompressionWorker.d.ts.map
