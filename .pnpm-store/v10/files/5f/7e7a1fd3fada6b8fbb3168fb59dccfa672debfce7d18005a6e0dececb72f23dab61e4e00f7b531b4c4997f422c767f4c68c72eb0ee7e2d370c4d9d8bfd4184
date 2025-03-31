import { CoreContext } from '../context'

/**
 * This is the base contract for all emitted errors. This interface may be extended.
 */
export interface CoreEmittedError<Ctx extends CoreContext> {
  /**
   * e.g. 'delivery_failure'
   */
  code: string
  /**
   * Why the error occurred. This can be an actual error object or a just a message.
   */
  reason?: unknown
  ctx?: Ctx
}

export type CoreEmitterContract<
  Ctx extends CoreContext,
  Err extends CoreEmittedError<Ctx> = CoreEmittedError<Ctx>
> = {
  alias: [ctx: Ctx]
  track: [ctx: Ctx]
  identify: [ctx: Ctx]
  page: [ctx: Ctx]
  screen: [ctx: Ctx]
  group: [ctx: Ctx]
  register: [pluginNames: string[]]
  deregister: [pluginNames: string[]]
  error: [error: Err]
}
