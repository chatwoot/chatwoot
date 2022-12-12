import { Analytics } from '../../analytics'
import { Context } from '../context'

interface PluginConfig {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  options: any
  priority: 'critical' | 'non-critical' // whether AJS should expect this plugin to be loaded before starting event delivery
}

// enrichment - modifies the event. Enrichment can happen in parallel, by reducing all changes in the final event. Failures in this stage could halt event delivery.
// destination - runs in parallel at the end of the lifecycle. Cannot modify the event, can fail and not halt execution.
// utility - do not affect lifecycle. Should be run and executed once. Their `track/identify` calls don't really do anything. example

export interface Plugin {
  name: string
  version: string
  type: 'before' | 'after' | 'destination' | 'enrichment' | 'utility'

  isLoaded: () => boolean
  load: (
    ctx: Context,
    instance: Analytics,
    config?: PluginConfig
  ) => Promise<unknown>

  unload?: (ctx: Context, instance: Analytics) => Promise<unknown> | unknown

  ready?: () => Promise<unknown>
  track?: (ctx: Context) => Promise<Context> | Context
  identify?: (ctx: Context) => Promise<Context> | Context
  page?: (ctx: Context) => Promise<Context> | Context
  group?: (ctx: Context) => Promise<Context> | Context
  alias?: (ctx: Context) => Promise<Context> | Context
  screen?: (ctx: Context) => Promise<Context> | Context
}
