import { CoreSegmentEvent } from '../events/interfaces';
import { CoreLogger, LogLevel, LogMessage } from '../logger';
import { CoreStats, CoreMetric } from '../stats';
export interface SerializedContext {
    id: string;
    event: CoreSegmentEvent;
    logs: LogMessage[];
    metrics?: CoreMetric[];
}
export interface ContextFailedDelivery {
    reason: unknown;
}
export interface CancelationOptions {
    retry?: boolean;
    reason?: string;
    type?: string;
}
export declare class ContextCancelation {
    retry: boolean;
    type: string;
    reason?: string;
    constructor(options: CancelationOptions);
}
export declare abstract class CoreContext<Event extends CoreSegmentEvent = CoreSegmentEvent> {
    event: Event;
    logger: CoreLogger;
    stats: CoreStats;
    attempts: number;
    private _failedDelivery?;
    private _id;
    constructor(event: Event, id?: string, stats?: CoreStats, logger?: CoreLogger);
    static system(): void;
    isSame(other: CoreContext): boolean;
    cancel(error?: Error | ContextCancelation): never;
    log(level: LogLevel, message: string, extras?: object): void;
    get id(): string;
    updateEvent(path: string, val: unknown): Event;
    failedDelivery(): ContextFailedDelivery | undefined;
    setFailedDelivery(options: ContextFailedDelivery): void;
    logs(): LogMessage[];
    flush(): void;
    toJSON(): SerializedContext;
}
//# sourceMappingURL=index.d.ts.map