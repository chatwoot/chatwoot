import {
  Integrations,
  JSONObject,
  JSONValue,
  SegmentEvent,
} from '@/core/events'
import { Alias, Facade, Group, Identify, Page, Track } from '@segment/facade'
import { Analytics, InitOptions } from '../../analytics'
import { LegacySettings } from '../../browser'
import { isOffline, isOnline } from '../../core/connection'
import { Context, ContextCancelation } from '../../core/context'
import { isServer } from '../../core/environment'
import { Plugin } from '../../core/plugin'
import { attempt } from '../../core/queue/delivery'
import { asPromise } from '../../lib/as-promise'
import { mergedOptions } from '../../lib/merged-options'
import { pWhile } from '../../lib/p-while'
import { PriorityQueue } from '../../lib/priority-queue'
import { PersistedPriorityQueue } from '../../lib/priority-queue/persisted'
import {
  applyDestinationMiddleware,
  DestinationMiddlewareFunction,
} from '../middleware'
import { tsubMiddleware } from '../routing-middleware'
import { loadIntegration, resolveVersion, unloadIntegration } from './loader'
import { LegacyIntegration } from './types'

const klona = (evt: SegmentEvent): SegmentEvent =>
  JSON.parse(JSON.stringify(evt))

export type ClassType<T> = new (...args: unknown[]) => T

async function flushQueue(
  xt: Plugin,
  queue: PriorityQueue<Context>
): Promise<PriorityQueue<Context>> {
  const failedQueue: Context[] = []

  if (isOffline()) {
    return queue
  }

  await pWhile(
    () => queue.length > 0 && isOnline(),
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

export class LegacyDestination implements Plugin {
  name: string
  version: string
  settings: Record<string, JSONValue>
  options: InitOptions = {}
  type: Plugin['type'] = 'destination'
  middleware: DestinationMiddlewareFunction[] = []

  private _ready = false
  private _initialized = false
  private onReady: Promise<unknown> | undefined
  private onInitialize: Promise<unknown> | undefined

  integration: LegacyIntegration | undefined

  buffer: PriorityQueue<Context>
  flushing = false

  constructor(
    name: string,
    version: string,
    settings: Record<string, JSONValue> = {},
    options: InitOptions
  ) {
    this.name = name
    this.version = version
    this.settings = { ...settings }

    // AJS-Renderer sets an extraneous `type` setting that clobbers
    // existing type defaults. We need to remove it if it's present
    if (this.settings['type'] && this.settings['type'] === 'browser') {
      delete this.settings['type']
    }

    this.options = options
    this.buffer = new PersistedPriorityQueue(4, `dest-${name}`)

    this.scheduleFlush()
  }

  isLoaded(): boolean {
    return this._ready
  }

  ready(): Promise<unknown> {
    return this.onReady ?? Promise.resolve()
  }

  async load(ctx: Context, analyticsInstance: Analytics): Promise<void> {
    if (this._ready || this.onReady !== undefined) {
      return
    }

    this.integration = await loadIntegration(
      ctx,
      analyticsInstance,
      this.name,
      this.version,
      this.settings
    )

    this.onReady = new Promise((resolve) => {
      const onReadyFn = (): void => {
        this._ready = true
        resolve(true)
      }

      this.integration!.once('ready', onReadyFn)
    })

    this.onInitialize = new Promise((resolve) => {
      const onInit = (): void => {
        this._initialized = true
        resolve(true)
      }

      this.integration!.on('initialize', onInit)
    })

    try {
      ctx.stats.increment('analytics_js.integration.invoke', 1, [
        `method:initialize`,
        `integration_name:${this.name}`,
      ])

      this.integration.initialize()
    } catch (error) {
      ctx.stats.increment('analytics_js.integration.invoke.error', 1, [
        `method:initialize`,
        `integration_name:${this.name}`,
      ])

      throw error
    }
  }

  unload(_ctx: Context, _analyticsInstance: Analytics): Promise<void> {
    return unloadIntegration(this.name, this.version)
  }

  addMiddleware(...fn: DestinationMiddlewareFunction[]): void {
    this.middleware = this.middleware.concat(...fn)
  }

  shouldBuffer(ctx: Context): boolean {
    return (
      // page events can't be buffered because of destinations that automatically add page views
      ctx.event.type !== 'page' &&
      (isOffline() || this._ready === false || this._initialized === false)
    )
  }

  private async send<T extends Facade>(
    ctx: Context,
    clz: ClassType<T>,
    eventType: 'track' | 'identify' | 'page' | 'alias' | 'group'
  ): Promise<Context> {
    if (this.shouldBuffer(ctx)) {
      this.buffer.push(ctx)
      this.scheduleFlush()
      return ctx
    }

    const plan = this.options?.plan?.track
    const ev = ctx.event.event

    if (plan && ev && this.name !== 'Segment.io') {
      // events are always sent to segment (legacy behavior)
      const planEvent = plan[ev]
      if (planEvent?.enabled === false) {
        ctx.updateEvent('integrations', {
          ...ctx.event.integrations,
          All: false,
          'Segment.io': true,
        })
        ctx.cancel(
          new ContextCancelation({
            retry: false,
            reason: `Event ${ev} disabled for integration ${this.name} in tracking plan`,
            type: 'Dropped by plan',
          })
        )
        return ctx
      } else {
        ctx.updateEvent('integrations', {
          ...ctx.event.integrations,
          ...planEvent?.integrations,
        })
      }

      if (planEvent?.enabled && planEvent?.integrations[this.name] === false) {
        ctx.cancel(
          new ContextCancelation({
            retry: false,
            reason: `Event ${ev} disabled for integration ${this.name} in tracking plan`,
            type: 'Dropped by plan',
          })
        )
        return ctx
      }
    }

    const afterMiddleware = await applyDestinationMiddleware(
      this.name,
      klona(ctx.event),
      this.middleware
    )

    if (afterMiddleware === null) {
      return ctx
    }

    const event = new clz(afterMiddleware, {})

    ctx.stats.increment('analytics_js.integration.invoke', 1, [
      `method:${eventType}`,
      `integration_name:${this.name}`,
    ])

    try {
      if (this.integration) {
        await asPromise(
          this.integration.invoke.call(this.integration, eventType, event)
        )
      }
    } catch (err) {
      ctx.stats.increment('analytics_js.integration.invoke.error', 1, [
        `method:${eventType}`,
        `integration_name:${this.name}`,
      ])
      throw err
    }

    return ctx
  }

  async track(ctx: Context): Promise<Context> {
    return this.send(ctx, Track as ClassType<Track>, 'track')
  }

  async page(ctx: Context): Promise<Context> {
    if (this.integration?._assumesPageview && !this._initialized) {
      this.integration.initialize()
    }

    return this.onInitialize!.then(() => {
      return this.send(ctx, Page as ClassType<Page>, 'page')
    })
  }

  async identify(ctx: Context): Promise<Context> {
    return this.send(ctx, Identify as ClassType<Identify>, 'identify')
  }

  async alias(ctx: Context): Promise<Context> {
    return this.send(ctx, Alias as ClassType<Alias>, 'alias')
  }

  async group(ctx: Context): Promise<Context> {
    return this.send(ctx, Group as ClassType<Group>, 'group')
  }

  private scheduleFlush(): void {
    if (this.flushing) {
      return
    }

    // eslint-disable-next-line @typescript-eslint/no-misused-promises
    setTimeout(async () => {
      this.flushing = true
      this.buffer = await flushQueue(this, this.buffer)
      this.flushing = false

      if (this.buffer.todo > 0) {
        this.scheduleFlush()
      }
    }, Math.random() * 5000)
  }
}

export async function ajsDestinations(
  settings: LegacySettings,
  globalIntegrations: Integrations = {},
  options?: InitOptions
): Promise<LegacyDestination[]> {
  if (isServer()) {
    return []
  }

  if (settings.plan) {
    options = options ?? {}
    options.plan = settings.plan
  }

  const routingRules = settings.middlewareSettings?.routingRules ?? []
  const routingMiddleware = tsubMiddleware(routingRules)

  // merged remote CDN settings with user provided options
  const integrationOptions = mergedOptions(settings, options ?? {}) as Record<
    string,
    JSONObject
  >

  return Object.entries(settings.integrations)
    .map(([name, integrationSettings]) => {
      if (name.startsWith('Segment')) {
        return
      }

      const allDisableAndNotDefined =
        globalIntegrations.All === false &&
        globalIntegrations[name] === undefined

      if (globalIntegrations[name] === false || allDisableAndNotDefined) {
        return
      }

      const { type, bundlingStatus, versionSettings } = integrationSettings
      // We use `!== 'unbundled'` (versus `=== 'bundled'`) to be inclusive of
      // destinations without a defined value for `bundlingStatus`
      const deviceMode =
        bundlingStatus !== 'unbundled' &&
        (type === 'browser' ||
          versionSettings?.componentTypes?.includes('browser'))

      // checking for iterable is a quick fix we need in place to prevent
      // errors showing Iterable as a failed destiantion. Ideally, we should
      // fix the Iterable metadata instead, but that's a longer process.
      if ((!deviceMode && name !== 'Segment.io') || name === 'Iterable') {
        return
      }

      const version = resolveVersion(integrationSettings)
      const destination = new LegacyDestination(
        name,
        version,
        integrationOptions[name],
        options as object
      )

      const routing = routingRules.filter(
        (rule) => rule.destinationName === name
      )
      if (routing.length > 0) {
        destination.addMiddleware(routingMiddleware)
      }

      return destination
    })
    .filter((xt) => xt !== undefined) as LegacyDestination[]
}
