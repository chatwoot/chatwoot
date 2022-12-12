import { AnalyticsBrowser } from './browser'
import {
  AliasParams,
  DispatchedEvent,
  EventParams,
  PageParams,
  resolveAliasArguments,
  resolveArguments,
  resolvePageArguments,
  resolveUserArguments,
  UserParams,
} from './core/arguments-resolver'
import type { FormArgs, LinkArgs } from './core/auto-track'
import { Callback, invokeCallback } from './core/callback'
import { isOffline } from './core/connection'
import { Context } from './core/context'
import { Emitter } from './core/emitter'
import { EventFactory, Integrations, Plan, SegmentEvent } from './core/events'
import { Plugin } from './core/plugin'
import { EventQueue } from './core/queue/event-queue'
import { CookieOptions, Group, ID, User, UserOptions } from './core/user'
import autoBind from './lib/bind-all'
import { PersistedPriorityQueue } from './lib/priority-queue/persisted'
import type { LegacyDestination } from './plugins/ajs-destination'
import type { LegacyIntegration } from './plugins/ajs-destination/types'
import type {
  DestinationMiddlewareFunction,
  MiddlewareFunction,
} from './plugins/middleware'
import { version } from './generated/version'

const deprecationWarning =
  'This is being deprecated and will be not be available in future releases of Analytics JS'

// reference any pre-existing "analytics" object so a user can restore the reference
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const globalAny: any = global
const _analytics = globalAny.analytics

export interface AnalyticsSettings {
  writeKey: string
  timeout?: number
  plugins?: Plugin[]
  [key: string]: unknown
}

export interface InitOptions {
  initialPageview?: boolean
  cookie?: CookieOptions
  user?: UserOptions
  group?: UserOptions
  integrations?: Integrations
  plan?: Plan
  retryQueue?: boolean
}

export class Analytics extends Emitter {
  protected settings: AnalyticsSettings
  private _user: User
  private _group: Group
  private eventFactory: EventFactory
  private _debug = false

  initialized = false
  integrations: Integrations
  options: InitOptions
  queue: EventQueue

  constructor(
    settings: AnalyticsSettings,
    options?: InitOptions,
    queue?: EventQueue,
    user?: User,
    group?: Group
  ) {
    super()
    const cookieOptions = options?.cookie
    this.settings = settings
    this.settings.timeout = this.settings.timeout ?? 300
    this.queue =
      queue ??
      new EventQueue(
        new PersistedPriorityQueue(options?.retryQueue ? 4 : 1, 'event-queue')
      )
    this._user = user ?? new User(options?.user, cookieOptions).load()
    this._group = group ?? new Group(options?.group, cookieOptions).load()
    this.eventFactory = new EventFactory(this._user)
    this.integrations = options?.integrations ?? {}
    this.options = options ?? {}

    autoBind(this)
  }

  user = (): User => {
    return this._user
  }

  async track(...args: EventParams): Promise<DispatchedEvent> {
    const [name, data, opts, cb] = resolveArguments(...args)

    const segmentEvent = this.eventFactory.track(
      name,
      data as SegmentEvent['properties'],
      opts,
      this.integrations
    )

    return this.dispatch(segmentEvent, cb).then((ctx) => {
      this.emit('track', name, ctx.event.properties, ctx.event.options)
      return ctx
    })
  }

  async page(...args: PageParams): Promise<DispatchedEvent> {
    const [
      category,
      page,
      properties,
      options,
      callback,
    ] = resolvePageArguments(...args)

    const segmentEvent = this.eventFactory.page(
      category,
      page,
      properties,
      options,
      this.integrations
    )

    return this.dispatch(segmentEvent, callback).then((ctx) => {
      this.emit('page', category, page, ctx.event.properties, ctx.event.options)
      return ctx
    })
  }

  async identify(...args: UserParams): Promise<DispatchedEvent> {
    const [id, _traits, options, callback] = resolveUserArguments(this._user)(
      ...args
    )

    this._user.identify(id, _traits)
    const segmentEvent = this.eventFactory.identify(
      this._user.id(),
      this._user.traits(),
      options,
      this.integrations
    )

    return this.dispatch(segmentEvent, callback).then((ctx) => {
      this.emit(
        'identify',
        ctx.event.userId,
        ctx.event.traits,
        ctx.event.options
      )
      return ctx
    })
  }

  group(...args: UserParams): Promise<DispatchedEvent> | Group {
    if (args.length === 0) {
      return this._group
    }

    const [id, _traits, options, callback] = resolveUserArguments(this._group)(
      ...args
    )

    this._group.identify(id, _traits)
    const groupId = this._group.id()
    const groupTraits = this._group.traits()

    const segmentEvent = this.eventFactory.group(
      groupId,
      groupTraits,
      options,
      this.integrations
    )

    return this.dispatch(segmentEvent, callback).then((ctx) => {
      this.emit('group', ctx.event.groupId, ctx.event.traits, ctx.event.options)
      return ctx
    })
  }

  async alias(...args: AliasParams): Promise<DispatchedEvent> {
    const [to, from, options, callback] = resolveAliasArguments(...args)
    const segmentEvent = this.eventFactory.alias(
      to,
      from,
      options,
      this.integrations
    )
    return this.dispatch(segmentEvent, callback).then((ctx) => {
      this.emit('alias', to, from, ctx.event.options)
      return ctx
    })
  }

  async screen(...args: PageParams): Promise<DispatchedEvent> {
    const [
      category,
      page,
      properties,
      options,
      callback,
    ] = resolvePageArguments(...args)

    const segmentEvent = this.eventFactory.screen(
      category,
      page,
      properties,
      options,
      this.integrations
    )
    return this.dispatch(segmentEvent, callback).then((ctx) => {
      this.emit(
        'screen',
        category,
        page,
        ctx.event.properties,
        ctx.event.options
      )
      return ctx
    })
  }

  async trackClick(...args: LinkArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ './core/auto-track'
    )
    return autotrack.link.call(this, ...args)
  }

  async trackLink(...args: LinkArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ './core/auto-track'
    )
    return autotrack.link.call(this, ...args)
  }

  async trackSubmit(...args: FormArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ './core/auto-track'
    )
    return autotrack.form.call(this, ...args)
  }

  async trackForm(...args: FormArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ './core/auto-track'
    )
    return autotrack.form.call(this, ...args)
  }

  async register(...plugins: Plugin[]): Promise<Context> {
    const ctx = Context.system()

    const registrations = plugins.map((xt) =>
      this.queue.register(ctx, xt, this)
    )
    await Promise.all(registrations)

    return ctx
  }

  async deregister(...plugins: string[]): Promise<Context> {
    const ctx = Context.system()

    const deregistrations = plugins.map(async (pl) => {
      const plugin = this.queue.plugins.find((p) => p.name === pl)
      if (plugin) {
        return this.queue.deregister(ctx, plugin, this)
      } else {
        ctx.log('warn', `plugin ${pl} not found`)
      }
    })

    await Promise.all(deregistrations)

    return ctx
  }

  debug(toggle: boolean): Analytics {
    // Make sure legacy ajs debug gets turned off if it was enabled before upgrading.
    if (toggle === false && localStorage.getItem('debug')) {
      localStorage.removeItem('debug')
    }
    this._debug = toggle
    return this
  }

  reset(): void {
    this._user.reset()
  }

  timeout(timeout: number): void {
    this.settings.timeout = timeout
  }

  private async dispatch(
    event: SegmentEvent,
    callback?: Callback
  ): Promise<DispatchedEvent> {
    const ctx = new Context(event)

    if (isOffline() && !this.options.retryQueue) {
      return ctx
    }

    let dispatched: Context
    if (this.queue.isEmpty()) {
      dispatched = await this.queue.dispatchSingle(ctx)
    } else {
      dispatched = await this.queue.dispatch(ctx)
    }

    if (callback) {
      dispatched = await invokeCallback(
        dispatched,
        callback,
        this.settings.timeout
      )
    }
    if (this._debug) {
      dispatched.flush()
    }

    return dispatched
  }

  async addSourceMiddleware(fn: MiddlewareFunction): Promise<Analytics> {
    const { sourceMiddlewarePlugin } = await import(
      /* webpackChunkName: "middleware" */ './plugins/middleware'
    )

    const integrations: Record<string, boolean> = {}
    this.queue.plugins.forEach((plugin) => {
      if (plugin.type === 'destination') {
        return (integrations[plugin.name] = true)
      }
    })

    const plugin = sourceMiddlewarePlugin(fn, integrations)
    await this.register(plugin)
    return this
  }

  async addDestinationMiddleware(
    integrationName: string,
    ...middlewares: DestinationMiddlewareFunction[]
  ): Promise<Analytics> {
    const legacyDestinations = this.queue.plugins.filter(
      (xt) =>
        // xt instanceof LegacyDestination &&
        xt.name.toLowerCase() === integrationName.toLowerCase()
    ) as LegacyDestination[]

    legacyDestinations.forEach((destination) => {
      destination.addMiddleware(...middlewares)
    })
    return this
  }

  setAnonymousId(id?: string): ID {
    return this._user.anonymousId(id)
  }

  async queryString(query: string): Promise<Context[]> {
    const { queryString } = await import(
      /* webpackChunkName: "queryString" */ './core/query-string'
    )
    return queryString(this, query)
  }

  /**
   * @deprecated This function does not register a destination plugin.
   *
   * Instantiates a legacy Analytics.js destination.
   *
   * This function does not register the destination as an Analytics.JS plugin,
   * all the it does it to invoke the factory function back.
   */
  use(legacyPluginFactory: (analytics: Analytics) => void): Analytics {
    legacyPluginFactory(this)
    return this
  }

  async ready(
    callback: Function = (res: Promise<unknown>[]): Promise<unknown>[] => res
  ): Promise<unknown> {
    return Promise.all(
      this.queue.plugins.map((i) => (i.ready ? i.ready() : Promise.resolve()))
    ).then((res) => {
      callback(res)
      return res
    })
  }

  // analytics-classic api

  noConflict(): Analytics {
    console.warn(deprecationWarning)
    window.analytics = _analytics ?? this
    return this
  }

  normalize(msg: SegmentEvent): SegmentEvent {
    console.warn(deprecationWarning)
    return this.eventFactory.normalize(msg)
  }

  get failedInitializations(): string[] {
    console.warn(deprecationWarning)
    return this.queue.failedInitializations
  }

  get VERSION(): string {
    return version
  }

  async initialize(
    settings?: AnalyticsSettings,
    options?: InitOptions
  ): Promise<Analytics> {
    console.warn(deprecationWarning)
    if (settings) {
      await AnalyticsBrowser.load(settings, options)
    }
    this.options = options || {}
    return this
  }

  init = this.initialize.bind(this)

  async pageview(url: string): Promise<Analytics> {
    console.warn(deprecationWarning)
    await this.page({ path: url })
    return this
  }

  get plugins() {
    console.warn(deprecationWarning)
    // @ts-expect-error
    return this._plugins ?? {}
  }

  get Integrations() {
    console.warn(deprecationWarning)
    const integrations = this.queue.plugins
      .filter((plugin) => plugin.type === 'destination')
      .reduce((acc, plugin) => {
        const name = `${plugin.name
          .toLowerCase()
          .replace('.', '')
          .split(' ')
          .join('-')}Integration`

        // @ts-expect-error
        const integration = window[name] as
          | (LegacyIntegration & { Integration?: LegacyIntegration })
          | undefined

        if (!integration) {
          return acc
        }

        const nested = integration.Integration // hack - Google Analytics function resides in the "Integration" field
        if (nested) {
          acc[plugin.name] = nested
          return acc
        }

        acc[plugin.name] = integration as LegacyIntegration
        return acc
      }, {} as Record<string, LegacyIntegration>)

    return integrations
  }

  // analytics-classic stubs

  log() {
    console.warn(deprecationWarning)
    return
  }

  addIntegrationMiddleware() {
    console.warn(deprecationWarning)
    return
  }

  listeners() {
    console.warn(deprecationWarning)
    return
  }

  addEventListener() {
    console.warn(deprecationWarning)
    return
  }

  removeAllListeners() {
    console.warn(deprecationWarning)
    return
  }

  removeListener() {
    console.warn(deprecationWarning)
    return
  }

  removeEventListener() {
    console.warn(deprecationWarning)
    return
  }

  hasListeners() {
    console.warn(deprecationWarning)
    return
  }

  // This function is only used to add GA and Appcue, but these are already being added to Integrations by AJSN
  addIntegration() {
    console.warn(deprecationWarning)
    return
  }

  add() {
    console.warn(deprecationWarning)
    return
  }

  // snippet function
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  push(args: any[]) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const an = this as any
    const method = args.shift()
    if (method) {
      if (!an[method]) return
    }
    an[method].apply(this, args)
  }
}
