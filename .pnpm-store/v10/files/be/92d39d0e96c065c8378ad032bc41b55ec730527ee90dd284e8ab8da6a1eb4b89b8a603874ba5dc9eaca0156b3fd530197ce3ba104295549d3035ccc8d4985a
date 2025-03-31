import { CoreContext } from '../context';
import { Callback } from '../events/interfaces';
import { CoreEventQueue } from '../queue/event-queue';
import { Emitter } from '../emitter';
export declare type DispatchOptions<Ctx extends CoreContext = CoreContext> = {
    timeout?: number;
    debug?: boolean;
    callback?: Callback<Ctx>;
};
export declare const getDelay: (startTimeInEpochMS: number, timeoutInMS?: number | undefined) => number;
/**
 * Push an event into the dispatch queue and invoke any callbacks.
 *
 * @param event - Segment event to enqueue.
 * @param queue - Queue to dispatch against.
 * @param emitter - This is typically an instance of "Analytics" -- used for metrics / progress information.
 * @param options
 */
export declare function dispatch<Ctx extends CoreContext, EQ extends CoreEventQueue<Ctx>>(ctx: Ctx, queue: EQ, emitter: Emitter, options?: DispatchOptions<Ctx>): Promise<Ctx>;
//# sourceMappingURL=dispatch.d.ts.map