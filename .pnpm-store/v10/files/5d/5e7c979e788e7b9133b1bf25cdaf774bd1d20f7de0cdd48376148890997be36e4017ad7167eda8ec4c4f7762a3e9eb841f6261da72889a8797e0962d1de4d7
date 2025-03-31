import { getProcessEnv } from '../lib/get-process-env'
import { getCDN, setGlobalCDNUrl } from '../lib/parse-cdn'
import { Analytics, AnalyticsSettings, InitOptions } from '../core/analytics'
import { Context } from '../core/context'
import { Plan } from '../core/events'
import { Plugin } from '../core/plugin'
import { MetricsOptions } from '../core/stats/remote-metrics'
import { mergedOptions } from '../lib/merged-options'
import { createDeferred } from '../lib/create-deferred'
import { pageEnrichment } from '../plugins/page-enrichment'
import { remoteLoader, RemotePlugin } from '../plugins/remote-loader'
import type { RoutingRule } from '../plugins/routing-middleware'
import { segmentio, SegmentioSettings } from '../plugins/segmentio'
import { validation } from '../plugins/validation'
import {
  AnalyticsBuffered,
  PreInitMethodCallBuffer,
  flushAnalyticsCallsInNewTask,
  flushAddSourceMiddleware,
  flushSetAnonymousID,
  flushOn,
} from '../core/buffer'
import { popSnippetWindowBuffer } from '../core/buffer/snippet'
import { ClassicIntegrationSource } from '../plugins/ajs-destination/types'
import { attachInspector } from '../core/inspector'
import { Stats } from '../core/stats'

export interface LegacyIntegrationConfiguration {
  /* @deprecated - This does not indicate browser types anymore */
  type?: string

  versionSettings?: {
    version?: string
    override?: string
    componentTypes?: Array<'browser' | 'android' | 'ios' | 'server'>
  }

  bundlingStatus?: string

  // june.so specific
  retryQueue?: boolean

  // any extra unknown settings
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [key: string]: any
}

export interface LegacySettings {
  integrations: {
    [name: string]: LegacyIntegrationConfiguration
  }

  middlewareSettings?: {
    routingRules: RoutingRule[]
  }

  enabledMiddleware?: Record<string, boolean>
  metrics?: MetricsOptions

  plan?: Plan

  legacyVideoPluginsEnabled?: boolean

  remotePlugins?: RemotePlugin[]
}

export interface AnalyticsBrowserSettings extends AnalyticsSettings {
  /**
   * The settings for the Segment Source.
   * If provided, `AnalyticsBrowser` will not fetch remote settings
   * for the source.
   */
  cdnSettings?: LegacySettings & Record<string, unknown>
  /**
   * If provided, will override the default Segment CDN (https://cdn.june.so) for this application.
   */
  cdnURL?: string
}

export function loadLegacySettings(
  cdnURL?: string
): LegacySettings {
  const baseUrl = cdnURL ?? getCDN()
  baseUrl;

  return {
    integrations: {}
  }
}

function hasLegacyDestinations(settings: LegacySettings): boolean {
  return (
    getProcessEnv().NODE_ENV !== 'test' &&
    // just one integration means segmentio
    Object.keys(settings.integrations).length > 1
  )
}

function hasTsubMiddleware(settings: LegacySettings): boolean {
  return (
    getProcessEnv().NODE_ENV !== 'test' &&
    (settings.middlewareSettings?.routingRules?.length ?? 0) > 0
  )
}

/**
 * With AJS classic, we allow users to call setAnonymousId before the library initialization.
 * This is important because some of the destinations will use the anonymousId during the initialization,
 * and if we set anonId afterwards, that wouldn’t impact the destination.
 *
 * Also Ensures events can be registered before library initialization.
 * This is important so users can register to 'initialize' and any events that may fire early during setup.
 */
function flushPreBuffer(
  analytics: Analytics,
  buffer: PreInitMethodCallBuffer
): void {
  buffer.push(...popSnippetWindowBuffer())
  flushSetAnonymousID(analytics, buffer)
  flushOn(analytics, buffer)
}

/**
 * Finish flushing buffer and cleanup.
 */
async function flushFinalBuffer(
  analytics: Analytics,
  buffer: PreInitMethodCallBuffer
): Promise<void> {
  // Call popSnippetWindowBuffer before each flush task since there may be
  // analytics calls during async function calls.
  buffer.push(...popSnippetWindowBuffer())
  await flushAddSourceMiddleware(analytics, buffer)
  buffer.push(...popSnippetWindowBuffer())
  flushAnalyticsCallsInNewTask(analytics, buffer)
  // Clear buffer, just in case analytics is loaded twice; we don't want to fire events off again.
  buffer.clear()
}

async function registerPlugins(
  legacySettings: LegacySettings,
  analytics: Analytics,
  opts: InitOptions,
  options: InitOptions,
  plugins: Plugin[],
  legacyIntegrationSources: ClassicIntegrationSource[]
): Promise<Context> {
  const tsubMiddleware = hasTsubMiddleware(legacySettings)
    ? await import(
        /* webpackChunkName: "tsub-middleware" */ '../plugins/routing-middleware'
      ).then((mod) => {
        return mod.tsubMiddleware(
          legacySettings.middlewareSettings!.routingRules
        )
      })
    : undefined

  const legacyDestinations =
    hasLegacyDestinations(legacySettings) || legacyIntegrationSources.length > 0
      ? await import(
          /* webpackChunkName: "ajs-destination" */ '../plugins/ajs-destination'
        ).then((mod) => {
          return mod.ajsDestinations(
            legacySettings,
            analytics.integrations,
            opts,
            tsubMiddleware,
            legacyIntegrationSources
          )
        })
      : []

  if (legacySettings.legacyVideoPluginsEnabled) {
    await import(
      /* webpackChunkName: "legacyVideos" */ '../plugins/legacy-video-plugins'
    ).then((mod) => {
      return mod.loadLegacyVideoPlugins(analytics)
    })
  }

  const schemaFilter = opts.plan?.track
    ? await import(
        /* webpackChunkName: "schemaFilter" */ '../plugins/schema-filter'
      ).then((mod) => {
        return mod.schemaFilter(opts.plan?.track, legacySettings)
      })
    : undefined

  const mergedSettings = mergedOptions(legacySettings, options)
  const remotePlugins = await remoteLoader(
    legacySettings,
    analytics.integrations,
    mergedSettings,
    options.obfuscate,
    tsubMiddleware
  ).catch(() => [])

  const toRegister = [
    validation,
    pageEnrichment,
    ...plugins,
    ...legacyDestinations,
    ...remotePlugins,
  ]

  if (schemaFilter) {
    toRegister.push(schemaFilter)
  }

  const shouldIgnoreSegmentio =
    (opts.integrations?.All === false && !opts.integrations['june.so']) ||
    (opts.integrations && opts.integrations['june.so'] === false)

  if (!shouldIgnoreSegmentio) {
    toRegister.push(
      segmentio(
        analytics,
        mergedSettings['june.so'] as SegmentioSettings,
        legacySettings.integrations
      )
    )
  }

  const ctx = await analytics.register(...toRegister)

  if (
    Object.entries(legacySettings.enabledMiddleware ?? {}).some(
      ([, enabled]) => enabled
    )
  ) {
    await import(
      /* webpackChunkName: "remoteMiddleware" */ '../plugins/remote-middleware'
    ).then(async ({ remoteMiddlewares }) => {
      const middleware = await remoteMiddlewares(
        ctx,
        legacySettings,
        options.obfuscate
      )
      const promises = middleware.map((mdw) =>
        analytics.addSourceMiddleware(mdw)
      )
      return Promise.all(promises)
    })
  }

  return ctx
}

async function loadAnalytics(
  settings: AnalyticsBrowserSettings,
  options: InitOptions = {},
  preInitBuffer: PreInitMethodCallBuffer
): Promise<[Analytics, Context]> {
  // this is an ugly side-effect, but it's for the benefits of the plugins that get their cdn via getCDN()
  if (settings.cdnURL) setGlobalCDNUrl(settings.cdnURL)

  const legacySettings =
    settings.cdnSettings ??
    (await loadLegacySettings(settings.writeKey))

  const retryQueue: boolean = true

  const opts: InitOptions = { retryQueue, ...options }
  const analytics = new Analytics(settings, opts)

  attachInspector(analytics)

  const plugins = settings.plugins ?? []
  const classicIntegrations = settings.classicIntegrations ?? []
  Stats.initRemoteMetrics(legacySettings.metrics)

  // needs to be flushed before plugins are registered
  flushPreBuffer(analytics, preInitBuffer)

  const ctx = await registerPlugins(
    legacySettings,
    analytics,
    opts,
    options,
    plugins,
    classicIntegrations
  )

  const search = window.location.search ?? ''
  const hash = window.location.hash ?? ''

  const term = search.length ? search : hash.replace(/(?=#).*(?=\?)/, '')

  if (term.includes('ajs_')) {
    await analytics.queryString(term).catch(console.error)
  }

  analytics.initialized = true
  analytics.emit('initialize', settings, options)

  if (options.initialPageview) {
    analytics.page().catch(console.error)
  }

  await flushFinalBuffer(analytics, preInitBuffer)

  return [analytics, ctx]
}

/**
 * The public browser interface for Segment Analytics
 *
 * @example
 * ```ts
 *  export const analytics = new AnalyticsBrowser()
 *  analytics.load({ writeKey: 'foo' })
 * ```
 * @link https://github.com/segmentio/analytics-next/#readme
 */
export class AnalyticsBrowser extends AnalyticsBuffered {
  private _resolveLoadStart: (
    settings: AnalyticsBrowserSettings,
    options: InitOptions
  ) => void

  constructor() {
    const { promise: loadStart, resolve: resolveLoadStart } =
      createDeferred<Parameters<AnalyticsBrowser['load']>>()

    super((buffer) =>
      loadStart.then(([settings, options]) =>
        loadAnalytics(settings, options, buffer)
      )
    )

    this._resolveLoadStart = (settings, options) =>
      resolveLoadStart([settings, options])
  }

  /**
   * Fully initialize an analytics instance, including:
   *
   * * Fetching settings from the segment CDN (by default).
   * * Fetching all remote destinations configured by the user (if applicable).
   * * Flushing buffered analytics events.
   * * Loading all middleware.
   *
   * Note:️  This method should only be called *once* in your application.
   *
   * @example
   * ```ts
   * export const analytics = new AnalyticsBrowser()
   * analytics.load({ writeKey: 'foo' })
   * ```
   */
  load(
    settings: AnalyticsBrowserSettings,
    options: InitOptions = {}
  ): AnalyticsBrowser {
    this._resolveLoadStart(settings, options)
    return this
  }

  /**
   * Instantiates an object exposing Analytics methods.
   *
   * @example
   * ```ts
   * const ajs = AnalyticsBrowser.load({ writeKey: '<YOUR_WRITE_KEY>' })
   *
   * ajs.track("foo")
   * ...
   * ```
   */
  static load(
    settings: AnalyticsBrowserSettings,
    options: InitOptions = {}
  ): AnalyticsBrowser {
    return new AnalyticsBrowser().load(settings, options)
  }

  static standalone(
    writeKey: string,
    options?: InitOptions
  ): Promise<Analytics> {
    return AnalyticsBrowser.load({ writeKey }, options).then((res) => res[0])
  }
}
