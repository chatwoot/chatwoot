import { Integrations } from '@segment/analytics-core'
import { LegacyIntegrationConfiguration } from '../..'

export const isInstallableIntegration = (
  name: string,
  integrationSettings: LegacyIntegrationConfiguration
) => {
  const { type, bundlingStatus, versionSettings } = integrationSettings
  // We use `!== 'unbundled'` (versus `=== 'bundled'`) to be inclusive of
  // destinations without a defined value for `bundlingStatus`
  const deviceMode =
    bundlingStatus !== 'unbundled' &&
    (type === 'browser' || versionSettings?.componentTypes?.includes('browser'))

  // checking for iterable is a quick fix we need in place to prevent
  // errors showing Iterable as a failed destiantion. Ideally, we should
  // fix the Iterable metadata instead, but that's a longer process.
  return !name.startsWith('Segment') && name !== 'Iterable' && deviceMode
}

export const isDisabledIntegration = (
  integrationName: string,
  globalIntegrations: Integrations
) => {
  const allDisableAndNotDefined =
    globalIntegrations.All === false &&
    globalIntegrations[integrationName] === undefined

  return (
    globalIntegrations[integrationName] === false || allDisableAndNotDefined
  )
}
