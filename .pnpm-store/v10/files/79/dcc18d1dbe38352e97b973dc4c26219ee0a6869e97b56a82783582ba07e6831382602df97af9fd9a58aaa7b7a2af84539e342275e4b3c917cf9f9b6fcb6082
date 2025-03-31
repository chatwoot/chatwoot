import { isOffline } from '../../core/connection'
import { Context } from '../../core/context'
import { Plugin } from '../../core/plugin'
import { attempt } from '@segment/analytics-core'
import { pWhile } from '../../lib/p-while'
import { PriorityQueue } from '../../lib/priority-queue'

async function flushQueue(
  xt: Plugin,
  queue: PriorityQueue<Context>
): Promise<PriorityQueue<Context>> {
  const failedQueue: Context[] = []
  if (isOffline()) {
    return queue
  }

  await pWhile(
    () => queue.length > 0 && !isOffline(),
    async () => {
      const ctx = queue.pop()
      if (!ctx) {
        return
      }

      const result = await attempt(ctx, xt)
      const success = result instanceof Context
      if (!success) {
        failedQueue.push(ctx)
      }
    }
  )
  // re-add failed tasks
  failedQueue.map((failed) => queue.pushWithBackoff(failed))
  return queue
}

export function scheduleFlush(
  flushing: boolean,
  buffer: PriorityQueue<Context>,
  xt: Plugin,
  scheduleFlush: Function
): void {
  if (flushing) {
    return
  }

  // eslint-disable-next-line @typescript-eslint/no-misused-promises
  setTimeout(async () => {
    let isFlushing = true
    // eslint-disable-next-line @typescript-eslint/no-use-before-define
    const newBuffer = await flushQueue(xt, buffer)
    isFlushing = false

    if (buffer.todo > 0) {
      scheduleFlush(isFlushing, newBuffer, xt, scheduleFlush)
    }
  }, Math.random() * 5000)
}
