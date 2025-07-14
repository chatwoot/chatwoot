import { LegacySettings } from '../../browser'
import { Context } from '../../core/context'
import { isServer } from '../../core/environment'
import { loadScript } from '../../lib/load-script'
import { getNextIntegrationsURL } from '../../lib/parse-cdn'
import { MiddlewareFunction } from '../middleware'

export async function remoteMiddlewares(
  ctx: Context,
  settings: LegacySettings,
  obfuscate?: boolean
): Promise<MiddlewareFunction[]> {
  if (isServer()) {
    return []
  }
  const path = getNextIntegrationsURL()
  const remoteMiddleware = settings.enabledMiddleware ?? {}
  const names = Object.entries(remoteMiddleware)
    .filter(([_, enabled]) => enabled)
    .map(([name]) => name)

  const scripts = names.map(async (name) => {
    const nonNamespaced = name.replace('@segment/', '')
    let bundleName = nonNamespaced
    if (obfuscate) {
      bundleName = btoa(nonNamespaced).replace(/=/g, '')
    }
    const fullPath = `${path}/middleware/${bundleName}/latest/${bundleName}.js.gz`

    try {
      await loadScript(fullPath)
      // @ts-ignore
      return window[`${nonNamespaced}Middleware`] as MiddlewareFunction
    } catch (error: any) {
      ctx.log('error', error)
      ctx.stats.increment('failed_remote_middleware')
    }
  })

  let middleware = await Promise.all(scripts)
  middleware = middleware.filter(Boolean)

  return middleware as MiddlewareFunction[]
}
