import { Analytics } from '../../core/analytics'
import { LegacyIntegrationConfiguration } from '../../browser'
import { getNextIntegrationsURL } from '../../lib/parse-cdn'
import { Context } from '../../core/context'
import { User } from '../../core/user'
import { loadScript, unloadScript } from '../../lib/load-script'
import {
  LegacyIntegration,
  ClassicIntegrationBuilder,
  ClassicIntegrationSource,
} from './types'

function normalizeName(name: string): string {
  return name.toLowerCase().replace('.', '').replace(/\s+/g, '-')
}

function obfuscatePathName(pathName: string, obfuscate = false): string | void {
  return obfuscate ? btoa(pathName).replace(/=/g, '') : undefined
}

export function resolveIntegrationNameFromSource(
  integrationSource: ClassicIntegrationSource
) {
  return (
    'Integration' in integrationSource
      ? integrationSource.Integration
      : integrationSource
  ).prototype.name
}

function recordLoadMetrics(fullPath: string, ctx: Context, name: string): void {
  try {
    const [metric] =
      window?.performance?.getEntriesByName(fullPath, 'resource') ?? []
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

export function buildIntegration(
  integrationSource: ClassicIntegrationSource,
  integrationSettings: { [key: string]: any },
  analyticsInstance: Analytics
): LegacyIntegration {
  let integrationCtr: ClassicIntegrationBuilder
  // GA and Appcues use a different interface to instantiating integrations
  if ('Integration' in integrationSource) {
    const analyticsStub = {
      user: (): User => analyticsInstance.user(),
      addIntegration: (): void => {},
    }

    integrationSource(analyticsStub)
    integrationCtr = integrationSource.Integration
  } else {
    integrationCtr = integrationSource
  }

  const integration = new integrationCtr(integrationSettings)
  integration.analytics = analyticsInstance
  return integration
}

export async function loadIntegration(
  ctx: Context,
  name: string,
  version: string,
  obfuscate?: boolean
): Promise<ClassicIntegrationSource> {
  const pathName = normalizeName(name)
  const obfuscatedPathName = obfuscatePathName(pathName, obfuscate)
  const path = getNextIntegrationsURL()

  const fullPath = `${path}/integrations/${
    obfuscatedPathName ?? pathName
  }/${version}/${obfuscatedPathName ?? pathName}.dynamic.js.gz`

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

  return window[
    // @ts-ignore
    `${pathName}Integration`
  ] as ClassicIntegrationSource
}

export async function unloadIntegration(
  name: string,
  version: string,
  obfuscate?: boolean
): Promise<void> {
  const path = getNextIntegrationsURL()
  const pathName = normalizeName(name)
  const obfuscatedPathName = obfuscatePathName(name, obfuscate)

  const fullPath = `${path}/integrations/${
    obfuscatedPathName ?? pathName
  }/${version}/${obfuscatedPathName ?? pathName}.dynamic.js.gz`

  return unloadScript(fullPath)
}

export function resolveVersion(
  settings?: LegacyIntegrationConfiguration
): string {
  return (
    settings?.versionSettings?.override ??
    settings?.versionSettings?.version ??
    'latest'
  )
}
