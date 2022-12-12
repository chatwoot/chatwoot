import { Analytics } from '../../analytics'
import { LegacyIntegrationConfiguration } from '../../browser'
import { getCDN } from '../../lib/parse-cdn'
import { Context } from '../../core/context'
import { User } from '../../core/user'
import { loadScript, unloadScript } from '../../lib/load-script'
import { LegacyIntegration } from './types'

const cdn = window.analytics?._cdn ?? getCDN()
const path = cdn + '/next-integrations'

function normalizeName(name: string): string {
  return name.toLowerCase().replace('.', '').replace(/\s+/g, '-')
}

function recordLoadMetrics(fullPath: string, ctx: Context, name: string): void {
  try {
    const [metric] =
      global.window?.performance?.getEntriesByName(fullPath, 'resource') ?? []
    // we assume everything that took under 100ms is cached
    metric &&
      ctx.stats.gauge('legacy_destination_time', Math.round(metric.duration), [
        name,
        ...(metric.duration < 100 ? ['cached'] : []),
      ])
  } catch (_) {
    // not available
  }
}

export async function loadIntegration(
  ctx: Context,
  analyticsInstance: Analytics,
  name: string,
  version: string,
  settings?: object
): Promise<LegacyIntegration> {
  const pathName = normalizeName(name)
  const fullPath = `${path}/integrations/${pathName}/${version}/${pathName}.dynamic.js.gz`

  try {
    await loadScript(fullPath)
    recordLoadMetrics(fullPath, ctx, name)
  } catch (err) {
    ctx.stats.gauge('legacy_destination_time', -1, [`plugin:${name}`, `failed`])
    throw err
  }

  // @ts-ignore
  const deps: string[] = window[`${pathName}Deps`]
  await Promise.all(deps.map((dep) => loadScript(path + dep + '.gz')))

  // @ts-ignore
  window[`${pathName}Loader`]()

  // @ts-ignore
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let integrationBuilder = window[`${pathName}Integration`] as any

  // GA and Appcues use a different interface to instantiating integrations
  if (integrationBuilder.Integration) {
    const analyticsStub = {
      user: (): User => analyticsInstance.user(),
      addIntegration: (): void => {},
    }

    integrationBuilder(analyticsStub)
    integrationBuilder = integrationBuilder.Integration
  }

  const integration = new integrationBuilder(settings) as LegacyIntegration
  integration.analytics = analyticsInstance

  return integration
}

export async function unloadIntegration(
  name: string,
  version: string
): Promise<void> {
  const pathName = normalizeName(name)
  return unloadScript(
    `${path}/integrations/${pathName}/${version}/${pathName}.dynamic.js.gz`
  )
}

export function resolveVersion(
  settings: LegacyIntegrationConfiguration
): string {
  return (
    settings.versionSettings?.override ??
    settings.versionSettings?.version ??
    'latest'
  )
}
