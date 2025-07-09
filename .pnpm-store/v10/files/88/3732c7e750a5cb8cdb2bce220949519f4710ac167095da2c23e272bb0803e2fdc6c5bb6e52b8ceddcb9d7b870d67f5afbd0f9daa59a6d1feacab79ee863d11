import { CoreAnalytics } from '../analytics'
import { groupBy } from '../utils/group-by'
import { ON_REMOVE_FROM_FUTURE, PriorityQueue } from '../priority-queue'

import { CoreContext, ContextCancelation } from '../context'
import { Emitter } from '../emitter'
import { Integrations, JSONObject } from '../events/interfaces'
import { CorePlugin } from '../plugins'
import { createTaskGroup, TaskGroup } from '../task/task-group'
import { attempt, ensure } from './delivery'
import { isOffline } from '../connection'

export type EventQueueEmitterContract<Ctx extends CoreContext> = {
  message_delivered: [ctx: Ctx]
  message_enriched: [ctx: Ctx, plugin: CorePlugin<Ctx>]
  delivery_success: [ctx: Ctx]
  delivery_retry: [ctx: Ctx]
  delivery_failure: [ctx: Ctx, err: Ctx | Error | ContextCancelation]
  flush: [ctx: Ctx, delivered: boolean]
}

export abstract class CoreEventQueue<
  Ctx extends CoreContext = CoreContext,
  Plugin extends CorePlugin<Ctx> = CorePlugin<Ctx>
> extends Emitter<EventQueueEmitterContract<Ctx>> {
  /**
   * All event deliveries get suspended until all the tasks in this task group are complete.
   * For example: a middleware that augments the event object should be loaded safely as a
   * critical task, this way, event queue will wait for it to be ready before sending events.
   *
   * This applies to all the events already in the queue, and the upcoming ones
   */
  criticalTasks: TaskGroup = createTaskGroup()
  queue: PriorityQueue<Ctx>
  plugins: Plugin[] = []
  failedInitializations: string[] = []
  private flushing = false

  constructor(priorityQueue: PriorityQueue<Ctx>) {
    super()

    this.queue = priorityQueue
    this.queue.on(ON_REMOVE_FROM_FUTURE, () => {
      this.scheduleFlush(0)
    })
  }

  async register(
    ctx: Ctx,
    plugin: Plugin,
    instance: CoreAnalytics
  ): Promise<void> {
    await Promise.resolve(plugin.load(ctx, instance))
      .then(() => {
        this.plugins.push(plugin)
      })
      .catch((err) => {
        if (plugin.type === 'destination') {
          this.failedInitializations.push(plugin.name)
          console.warn(plugin.name, err)

          ctx.log('warn', 'Failed to load destination', {
            plugin: plugin.name,
            error: err,
          })

          return
        }

        throw err
      })
  }

  async deregister(
    ctx: Ctx,
    plugin: CorePlugin<Ctx>,
    instance: CoreAnalytics
  ): Promise<void> {
    try {
      if (plugin.unload) {
        await Promise.resolve(plugin.unload(ctx, instance))
      }

      this.plugins = this.plugins.filter((p) => p.name !== plugin.name)
    } catch (e) {
      ctx.log('warn', 'Failed to unload destination', {
        plugin: plugin.name,
        error: e,
      })
    }
  }

  async dispatch(ctx: Ctx): Promise<Ctx> {
    ctx.log('debug', 'Dispatching')
    ctx.stats.increment('message_dispatched')

    this.queue.push(ctx)
    const willDeliver = this.subscribeToDelivery(ctx)
    this.scheduleFlush(0)
    return willDeliver
  }

  private async subscribeToDelivery(ctx: Ctx): Promise<Ctx> {
    return new Promise((resolve) => {
      const onDeliver = (flushed: Ctx, delivered: boolean): void => {
        if (flushed.isSame(ctx)) {
          this.off('flush', onDeliver)
          if (delivered) {
            resolve(flushed)
          } else {
            resolve(flushed)
          }
        }
      }

      this.on('flush', onDeliver)
    })
  }

  async dispatchSingle(ctx: Ctx): Promise<Ctx> {
    ctx.log('debug', 'Dispatching')
    ctx.stats.increment('message_dispatched')

    this.queue.updateAttempts(ctx)
    ctx.attempts = 1

    return this.deliver(ctx).catch((err) => {
      const accepted = this.enqueuRetry(err, ctx)
      if (!accepted) {
        ctx.setFailedDelivery({ reason: err })
        return ctx
      }

      return this.subscribeToDelivery(ctx)
    })
  }

  isEmpty(): boolean {
    return this.queue.length === 0
  }

  private scheduleFlush(timeout = 500): void {
    if (this.flushing) {
      return
    }

    this.flushing = true

    setTimeout(() => {
      // eslint-disable-next-line @typescript-eslint/no-floating-promises
      this.flush().then(() => {
        setTimeout(() => {
          this.flushing = false

          if (this.queue.length) {
            this.scheduleFlush(0)
          }
        }, 0)
      })
    }, timeout)
  }

  private async deliver(ctx: Ctx): Promise<Ctx> {
    await this.criticalTasks.done()

    const start = Date.now()
    try {
      ctx = await this.flushOne(ctx)
      const done = Date.now() - start
      this.emit('delivery_success', ctx)
      ctx.stats.gauge('delivered', done)
      ctx.log('debug', 'Delivered', ctx.event)
      return ctx
    } catch (err: any) {
      const error = err as Ctx | Error | ContextCancelation
      ctx.log('error', 'Failed to deliver', error)
      this.emit('delivery_failure', ctx, error)
      ctx.stats.increment('delivery_failed')
      throw err
    }
  }

  private enqueuRetry(err: Error, ctx: Ctx): boolean {
    const retriable = !(err instanceof ContextCancelation) || err.retry
    if (!retriable) {
      return false
    }

    return this.queue.pushWithBackoff(ctx)
  }

  async flush(): Promise<Ctx[]> {
    if (this.queue.length === 0 || isOffline()) {
      return []
    }

    let ctx = this.queue.pop()
    if (!ctx) {
      return []
    }

    ctx.attempts = this.queue.getAttempts(ctx)

    try {
      ctx = await this.deliver(ctx)
      this.emit('flush', ctx, true)
    } catch (err: any) {
      const accepted = this.enqueuRetry(err, ctx)

      if (!accepted) {
        ctx.setFailedDelivery({ reason: err })
        this.emit('flush', ctx, false)
      }

      return []
    }

    return [ctx]
  }

  private isReady(): boolean {
    // return this.plugins.every((p) => p.isLoaded())
    // should we wait for every plugin to load?
    return true
  }

  private availableExtensions(denyList: Integrations) {
    const available = this.plugins.filter((p) => {
      // Only filter out destination plugins or the Segment.io plugin
      if (p.type !== 'destination' && p.name !== 'Segment.io') {
        return true
      }

      let alternativeNameMatch: boolean | JSONObject | undefined = undefined
      p.alternativeNames?.forEach((name) => {
        if (denyList[name] !== undefined) {
          alternativeNameMatch = denyList[name]
        }
      })

      // Explicit integration option takes precedence, `All: false` does not apply to Segment.io
      return (
        denyList[p.name] ??
        alternativeNameMatch ??
        (p.name === 'Segment.io' ? true : denyList.All) !== false
      )
    })

    const {
      before = [],
      enrichment = [],
      destination = [],
      after = [],
    } = groupBy(available, 'type')

    return {
      before,
      enrichment,
      destinations: destination,
      after,
    }
  }

  private async flushOne(ctx: Ctx): Promise<Ctx> {
    if (!this.isReady()) {
      throw new Error('Not ready')
    }

    if (ctx.attempts > 1) {
      this.emit('delivery_retry', ctx)
    }

    const { before, enrichment } = this.availableExtensions(
      ctx.event.integrations ?? {}
    )

    for (const beforeWare of before) {
      const temp = await ensure(ctx, beforeWare)
      if (temp instanceof CoreContext) {
        ctx = temp
      }

      this.emit('message_enriched', ctx, beforeWare)
    }

    for (const enrichmentWare of enrichment) {
      const temp = await attempt(ctx, enrichmentWare)
      if (temp instanceof CoreContext) {
        ctx = temp
      }

      this.emit('message_enriched', ctx, enrichmentWare)
    }

    // Enrichment and before plugins can re-arrange the deny list dynamically
    // so we need to pluck them at the end
    const { destinations, after } = this.availableExtensions(
      ctx.event.integrations ?? {}
    )

    await new Promise((resolve, reject) => {
      setTimeout(() => {
        const attempts = destinations.map((destination) =>
          attempt(ctx, destination)
        )
        Promise.all(attempts).then(resolve).catch(reject)
      }, 0)
    })

    ctx.stats.increment('message_delivered')

    this.emit('message_delivered', ctx)

    const afterCalls = after.map((after) => attempt(ctx, after))
    await Promise.all(afterCalls)

    return ctx
  }
}
