import {
  AliasParams,
  DispatchedEvent,
  EventParams,
  GroupParams,
  PageParams,
  resolveAliasArguments,
  resolveArguments,
  resolvePageArguments,
  resolveUserArguments,
  IdentifyParams,
} from '../arguments-resolver'
import type { FormArgs, LinkArgs } from '../auto-track'
import { isOffline } from '../connection'
import { Context } from '../context'
import { dispatch, Emitter } from '@segment/analytics-core'
import {
  Callback,
  EventFactory,
  Integrations,
  Plan,
  EventProperties,
  SegmentEvent,
} from '../events'
import type { Plugin } from '../plugin'
import { EventQueue } from '../queue/event-queue'
import {
  CookieOptions,
  getAvailableStorageOptions,
  Group,
  ID,
  UniversalStorage,
  User,
  UserOptions,
} from '../user'
import autoBind from '../../lib/bind-all'
import { PersistedPriorityQueue } from '../../lib/priority-queue/persisted'
import type { LegacyDestination } from '../../plugins/ajs-destination'
import type {
  LegacyIntegration,
  ClassicIntegrationSource,
} from '../../plugins/ajs-destination/types'
import type {
  DestinationMiddlewareFunction,
  MiddlewareFunction,
} from '../../plugins/middleware'
import { version } from '../../generated/version'
import { PriorityQueue } from '../../lib/priority-queue'
import { getGlobal } from '../../lib/get-global'
import { AnalyticsClassic, AnalyticsCore } from './interfaces'

const deprecationWarning =
  'This is being deprecated and will be not be available in future releases of Analytics JS'

// reference any pre-existing "analytics" object so a user can restore the reference
const global: any = getGlobal()
const _analytics = global?.analytics

function createDefaultQueue(retryQueue = false, disablePersistance = false) {
  const maxAttempts = retryQueue ? 4 : 1
  const priorityQueue = disablePersistance
    ? new PriorityQueue(maxAttempts, [])
    : new PersistedPriorityQueue(maxAttempts, 'event-queue')
  return new EventQueue(priorityQueue)
}

export interface AnalyticsSettings {
  writeKey: string
  timeout?: number
  plugins?: Plugin[]
  classicIntegrations?: ClassicIntegrationSource[]
}

export interface InitOptions {
  /**
   * Disables storing any data on the client-side via cookies or localstorage.
   * Defaults to `false`.
   *
   */
  disableClientPersistence?: boolean
  /**
   * Disables automatically converting ISO string event properties into Dates.
   * ISO string to Date conversions occur right before sending events to a classic device mode integration,
   * after any destination middleware have been ran.
   * Defaults to `false`.
   */
  disableAutoISOConversion?: boolean
  initialPageview?: boolean
  cookie?: CookieOptions
  user?: UserOptions
  group?: UserOptions
  integrations?: Integrations
  plan?: Plan
  retryQueue?: boolean
  obfuscate?: boolean
  /**
   * Disables or sets constraints on processing of query string parameters
   */
  useQueryString?:
    | boolean
    | {
        aid?: RegExp
        uid?: RegExp
      }
}

/* analytics-classic stubs */
function _stub(this: never) {
  console.warn(deprecationWarning)
}

export class Analytics
  extends Emitter
  implements AnalyticsCore, AnalyticsClassic
{
  protected settings: AnalyticsSettings
  private _user: User
  private _group: Group
  private eventFactory: EventFactory
  private _debug = false
  private _universalStorage: UniversalStorage<{
    [k: string]: unknown
  }>

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
    const disablePersistance = options?.disableClientPersistence ?? false
    this.settings = settings
    this.settings.timeout = this.settings.timeout ?? 300
    this.queue =
      queue ?? createDefaultQueue(options?.retryQueue, disablePersistance)

    this._universalStorage = new UniversalStorage(
      disablePersistance ? ['memory'] : ['localStorage', 'cookie', 'memory'],
      getAvailableStorageOptions(cookieOptions)
    )

    this._user =
      user ??
      new User(
        disablePersistance
          ? { ...options?.user, persist: false }
          : options?.user,
        cookieOptions
      ).load()
    this._group =
      group ??
      new Group(
        disablePersistance
          ? { ...options?.group, persist: false }
          : options?.group,
        cookieOptions
      ).load()
    this.eventFactory = new EventFactory(this._user)
    this.integrations = options?.integrations ?? {}
    this.options = options ?? {}

    autoBind(this)
  }

  user = (): User => {
    return this._user
  }

  get storage(): UniversalStorage {
    return this._universalStorage
  }

  async track(...args: EventParams): Promise<DispatchedEvent> {
    const [name, data, opts, cb] = resolveArguments(...args)

    const segmentEvent = this.eventFactory.track(
      name,
      data as EventProperties,
      opts,
      this.integrations
    )

    return this._dispatch(segmentEvent, cb).then((ctx) => {
      this.emit('track', name, ctx.event.properties, ctx.event.options)
      return ctx
    })
  }

  async page(...args: PageParams): Promise<DispatchedEvent> {
    const [category, page, properties, options, callback] =
      resolvePageArguments(...args)

    const segmentEvent = this.eventFactory.page(
      category,
      page,
      properties,
      options,
      this.integrations
    )

    return this._dispatch(segmentEvent, callback).then((ctx) => {
      this.emit('page', category, page, ctx.event.properties, ctx.event.options)
      return ctx
    })
  }

  async identify(...args: IdentifyParams): Promise<DispatchedEvent> {
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

    return this._dispatch(segmentEvent, callback).then((ctx) => {
      this.emit(
        'identify',
        ctx.event.userId,
        ctx.event.traits,
        ctx.event.options
      )
      return ctx
    })
  }

  group(): Group
  group(...args: GroupParams): Promise<DispatchedEvent>
  group(...args: GroupParams): Promise<DispatchedEvent> | Group {
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

    return this._dispatch(segmentEvent, callback).then((ctx) => {
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
    return this._dispatch(segmentEvent, callback).then((ctx) => {
      this.emit('alias', to, from, ctx.event.options)
      return ctx
    })
  }

  async screen(...args: PageParams): Promise<DispatchedEvent> {
    const [category, page, properties, options, callback] =
      resolvePageArguments(...args)

    const segmentEvent = this.eventFactory.screen(
      category,
      page,
      properties,
      options,
      this.integrations
    )
    return this._dispatch(segmentEvent, callback).then((ctx) => {
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
      /* webpackChunkName: "auto-track" */ '../auto-track'
    )
    return autotrack.link.call(this, ...args)
  }

  async trackLink(...args: LinkArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ '../auto-track'
    )
    return autotrack.link.call(this, ...args)
  }

  async trackSubmit(...args: FormArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ '../auto-track'
    )
    return autotrack.form.call(this, ...args)
  }

  async trackForm(...args: FormArgs): Promise<Analytics> {
    const autotrack = await import(
      /* webpackChunkName: "auto-track" */ '../auto-track'
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

    const deregistrations = plugins.map((pl) => {
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
    this._group.reset()
    this.emit('reset')
  }

  timeout(timeout: number): void {
    this.settings.timeout = timeout
  }

  private async _dispatch(
    event: SegmentEvent,
    callback?: Callback
  ): Promise<DispatchedEvent> {
    const ctx = new Context(event)
    if (isOffline() && !this.options.retryQueue) {
      return ctx
    }
    return dispatch(ctx, this.queue, this, {
      callback,
      debug: this._debug,
      timeout: this.settings.timeout,
    })
  }

  async addSourceMiddleware(fn: MiddlewareFunction): Promise<Analytics> {
    await this.queue.criticalTasks.run(async () => {
      const { sourceMiddlewarePlugin } = await import(
        /* webpackChunkName: "middleware" */ '../../plugins/middleware'
      )

      const integrations: Record<string, boolean> = {}
      this.queue.plugins.forEach((plugin) => {
        if (plugin.type === 'destination') {
          return (integrations[plugin.name] = true)
        }
      })

      const plugin = sourceMiddlewarePlugin(fn, integrations)
      await this.register(plugin)
    })

    return this
  }

  /* TODO: This does not have to return a promise? */
  addDestinationMiddleware(
    integrationName: string,
    ...middlewares: DestinationMiddlewareFunction[]
  ): Promise<Analytics> {
    const legacyDestinations = this.queue.plugins.filter(
      (xt) => xt.name.toLowerCase() === integrationName.toLowerCase()
    ) as LegacyDestination[]

    legacyDestinations.forEach((destination) => {
      destination.addMiddleware(...middlewares)
    })
    return Promise.resolve(this)
  }

  setAnonymousId(id?: string): ID {
    return this._user.anonymousId(id)
  }

  async queryString(query: string): Promise<Context[]> {
    if (this.options.useQueryString === false) {
      return []
    }

    const { queryString } = await import(
      /* webpackChunkName: "queryString" */ '../query-string'
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

  /* @deprecated - noop */
  async initialize(
    _settings?: AnalyticsSettings,
    _options?: InitOptions
  ): Promise<Analytics> {
    console.warn(deprecationWarning)
    return Promise.resolve(this)
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

  log = _stub
  addIntegrationMiddleware = _stub
  listeners = _stub
  addEventListener = _stub
  removeAllListeners = _stub
  removeListener = _stub
  removeEventListener = _stub
  hasListeners = _stub
  add = _stub
  addIntegration = _stub

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
