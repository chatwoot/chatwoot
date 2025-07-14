import { CoreAnalytics } from '../analytics';
import { PriorityQueue } from '../priority-queue';
import { CoreContext, ContextCancelation } from '../context';
import { Emitter } from '../emitter';
import { CorePlugin } from '../plugins';
import { TaskGroup } from '../task/task-group';
export declare type EventQueueEmitterContract<Ctx extends CoreContext> = {
    message_delivered: [ctx: Ctx];
    message_enriched: [ctx: Ctx, plugin: CorePlugin<Ctx>];
    delivery_success: [ctx: Ctx];
    delivery_retry: [ctx: Ctx];
    delivery_failure: [ctx: Ctx, err: Ctx | Error | ContextCancelation];
    flush: [ctx: Ctx, delivered: boolean];
};
export declare abstract class CoreEventQueue<Ctx extends CoreContext = CoreContext, Plugin extends CorePlugin<Ctx> = CorePlugin<Ctx>> extends Emitter<EventQueueEmitterContract<Ctx>> {
    /**
     * All event deliveries get suspended until all the tasks in this task group are complete.
     * For example: a middleware that augments the event object should be loaded safely as a
     * critical task, this way, event queue will wait for it to be ready before sending events.
     *
     * This applies to all the events already in the queue, and the upcoming ones
     */
    criticalTasks: TaskGroup;
    queue: PriorityQueue<Ctx>;
    plugins: Plugin[];
    failedInitializations: string[];
    private flushing;
    constructor(priorityQueue: PriorityQueue<Ctx>);
    register(ctx: Ctx, plugin: Plugin, instance: CoreAnalytics): Promise<void>;
    deregister(ctx: Ctx, plugin: CorePlugin<Ctx>, instance: CoreAnalytics): Promise<void>;
    dispatch(ctx: Ctx): Promise<Ctx>;
    private subscribeToDelivery;
    dispatchSingle(ctx: Ctx): Promise<Ctx>;
    isEmpty(): boolean;
    private scheduleFlush;
    private deliver;
    private enqueuRetry;
    flush(): Promise<Ctx[]>;
    private isReady;
    private availableExtensions;
    private flushOne;
}
//# sourceMappingURL=event-queue.d.ts.map