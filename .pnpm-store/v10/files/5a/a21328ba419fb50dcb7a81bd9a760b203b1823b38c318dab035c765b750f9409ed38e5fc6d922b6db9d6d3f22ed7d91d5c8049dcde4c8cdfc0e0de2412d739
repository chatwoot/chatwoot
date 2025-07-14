import type { CoreAnalytics } from '../analytics'
import type { CoreContext } from '../context'

interface CorePluginConfig {
  options: any
  priority: 'critical' | 'non-critical' // whether AJS should expect this plugin to be loaded before starting event delivery
}

export type PluginType =
  | 'before'
  | 'after'
  | 'destination'
  | 'enrichment'
  | 'utility'

// enrichment - modifies the event. Enrichment can happen in parallel, by reducing all changes in the final event. Failures in this stage could halt event delivery.
// destination - runs in parallel at the end of the lifecycle. Cannot modify the event, can fail and not halt execution.
// utility - do not affect lifecycle. Should be run and executed once. Their `track/identify` calls don't really do anything. example

export interface CorePlugin<
  Ctx extends CoreContext = CoreContext,
  Analytics extends CoreAnalytics = any
> {
  name: string
  alternativeNames?: string[]
  version: string
  type: PluginType
  isLoaded: () => boolean
  load: (
    ctx: Ctx,
    instance: Analytics,
    config?: CorePluginConfig
  ) => Promise<unknown>

  unload?: (ctx: Ctx, instance: Analytics) => Promise<unknown> | unknown
  ready?: () => Promise<unknown>
  track?: (ctx: Ctx) => Promise<Ctx> | Ctx
  identify?: (ctx: Ctx) => Promise<Ctx> | Ctx
  page?: (ctx: Ctx) => Promise<Ctx> | Ctx
  group?: (ctx: Ctx) => Promise<Ctx> | Ctx
  alias?: (ctx: Ctx) => Promise<Ctx> | Ctx
  screen?: (ctx: Ctx) => Promise<Ctx> | Ctx
}
