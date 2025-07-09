import { CoreContext, ContextCancelation } from '../context'
import { CorePlugin } from '../plugins'

async function tryAsync<T>(fn: () => T | Promise<T>): Promise<T> {
  try {
    return await fn()
  } catch (err) {
    return Promise.reject(err)
  }
}

export function attempt<Ctx extends CoreContext = CoreContext>(
  ctx: Ctx,
  plugin: CorePlugin<Ctx>
): Promise<Ctx | ContextCancelation | Error> {
  ctx.log('debug', 'plugin', { plugin: plugin.name })
  const start = new Date().getTime()

  const hook = plugin[ctx.event.type]
  if (hook === undefined) {
    return Promise.resolve(ctx)
  }

  const newCtx = tryAsync(() => hook.apply(plugin, [ctx]))
    .then((ctx) => {
      const done = new Date().getTime() - start
      ctx.stats.gauge('plugin_time', done, [`plugin:${plugin.name}`])

      return ctx
    })
    .catch((err: Error | ContextCancelation) => {
      if (
        err instanceof ContextCancelation &&
        err.type === 'middleware_cancellation'
      ) {
        throw err
      }

      if (err instanceof ContextCancelation) {
        ctx.log('warn', err.type, {
          plugin: plugin.name,
          error: err,
        })

        return err
      }

      ctx.log('error', 'plugin Error', {
        plugin: plugin.name,
        error: err,
      })
      ctx.stats.increment('plugin_error', 1, [`plugin:${plugin.name}`])

      return err
    })

  return newCtx
}

export function ensure<Ctx extends CoreContext = CoreContext>(
  ctx: Ctx,
  plugin: CorePlugin<Ctx>
): Promise<Ctx | undefined> {
  return attempt(ctx, plugin).then((newContext) => {
    if (newContext instanceof CoreContext) {
      return newContext
    }

    ctx.log('debug', 'Context canceled')
    ctx.stats.increment('context_canceled')
    ctx.cancel(newContext)
  })
}
