import { CoreContext } from '../context'
import { Callback } from '../events/interfaces'
import { CoreEventQueue } from '../queue/event-queue'
import { invokeCallback } from '../callback'
import { Emitter } from '../emitter'

export type DispatchOptions<Ctx extends CoreContext = CoreContext> = {
  timeout?: number
  debug?: boolean
  callback?: Callback<Ctx>
}

/* The amount of time in ms to wait before invoking the callback. */
export const getDelay = (startTimeInEpochMS: number, timeoutInMS?: number) => {
  const elapsedTime = Date.now() - startTimeInEpochMS
  // increasing the timeout increases the delay by almost the same amount -- this is weird legacy behavior.
  return Math.max((timeoutInMS ?? 300) - elapsedTime, 0)
}
/**
 * Push an event into the dispatch queue and invoke any callbacks.
 *
 * @param event - Segment event to enqueue.
 * @param queue - Queue to dispatch against.
 * @param emitter - This is typically an instance of "Analytics" -- used for metrics / progress information.
 * @param options
 */
export async function dispatch<
  Ctx extends CoreContext,
  EQ extends CoreEventQueue<Ctx>
>(
  ctx: Ctx,
  queue: EQ,
  emitter: Emitter,
  options?: DispatchOptions<Ctx>
): Promise<Ctx> {
  emitter.emit('dispatch_start', ctx)

  const startTime = Date.now()
  let dispatched: Ctx
  if (queue.isEmpty()) {
    dispatched = await queue.dispatchSingle(ctx)
  } else {
    dispatched = await queue.dispatch(ctx)
  }

  if (options?.callback) {
    dispatched = await invokeCallback(
      dispatched,
      options.callback,
      getDelay(startTime, options.timeout)
    )
  }
  if (options?.debug) {
    dispatched.flush()
  }

  return dispatched
}
