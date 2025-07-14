import jar from 'js-cookie'
import { Analytics } from '../../core/analytics'
import { LegacySettings } from '../../browser'
import { SegmentEvent } from '../../core/events'
import { gracefulDecodeURIComponent } from '../../core/query-string/gracefulDecodeURIComponent'
import { tld } from '../../core/user/tld'
import { SegmentFacade } from '../../lib/to-facade'
import { SegmentioSettings } from './index'
import { version } from '../../generated/version'
import { getAvailableStorageOptions, UniversalStorage } from '../../core/user'

let cookieOptions: jar.CookieAttributes | undefined
function getCookieOptions(): jar.CookieAttributes {
  if (cookieOptions) {
    return cookieOptions
  }

  const domain = tld(window.location.href)
  cookieOptions = {
    expires: 31536000000, // 1 year
    secure: false,
    path: '/',
  }
  if (domain) {
    cookieOptions.domain = domain
  }

  return cookieOptions
}

// Default value will be updated to 'web' in `bundle-umd.ts` for web build.
let _version: 'web' | 'npm' = 'npm'

export function setVersionType(version: typeof _version) {
  _version = version
}

export function getVersionType(): typeof _version {
  return _version
}

type Ad = { id: string; type: string }

export function ampId(): string | undefined {
  const ampId = jar.get('_ga')
  if (ampId && ampId.startsWith('amp')) {
    return ampId
  }
}

export function utm(query: string): Record<string, string> {
  if (query.startsWith('?')) {
    query = query.substring(1)
  }
  query = query.replace(/\?/g, '&')

  return query.split('&').reduce((acc, str) => {
    const [k, v = ''] = str.split('=')
    if (k.includes('utm_') && k.length > 4) {
      let utmParam = k.substr(4)
      if (utmParam === 'campaign') {
        utmParam = 'name'
      }
      acc[utmParam] = gracefulDecodeURIComponent(v)
    }
    return acc
  }, {} as Record<string, string>)
}

function ads(query: string): Ad | undefined {
  const queryIds: Record<string, string> = {
    btid: 'dataxu',
    urid: 'millennial-media',
  }

  if (query.startsWith('?')) {
    query = query.substring(1)
  }
  query = query.replace(/\?/g, '&')
  const parts = query.split('&')

  for (const part of parts) {
    const [k, v] = part.split('=')
    if (queryIds[k]) {
      return {
        id: v,
        type: queryIds[k],
      }
    }
  }
}

function referrerId(
  query: string,
  ctx: SegmentEvent['context'],
  disablePersistance: boolean
): void {
  const storage = new UniversalStorage<{
    's:context.referrer': Ad
  }>(
    disablePersistance ? [] : ['cookie'],
    getAvailableStorageOptions(getCookieOptions())
  )

  const stored = storage.get('s:context.referrer')
  let ad: Ad | undefined | null = ads(query)

  ad = ad ?? stored

  if (!ad) {
    return
  }

  if (ctx) {
    ctx.referrer = { ...ctx.referrer, ...ad }
  }

  storage.set('s:context.referrer', ad)
}

export function normalize(
  analytics: Analytics,
  json: ReturnType<SegmentFacade['json']>,
  settings?: SegmentioSettings,
  integrations?: LegacySettings['integrations']
): object {
  const user = analytics.user()
  const query = window.location.search

  json.context = json.context ?? json.options ?? {}
  const ctx = json.context

  delete json.options
  json.writeKey = settings?.apiKey
  ctx.userAgent = window.navigator.userAgent

  // @ts-ignore
  const locale = navigator.userLanguage || navigator.language

  if (typeof ctx.locale === 'undefined' && typeof locale !== 'undefined') {
    ctx.locale = locale
  }

  if (!ctx.library) {
    const type = getVersionType()
    if (type === 'web') {
      ctx.library = {
        name: 'analytics.js',
        version: `next-${version}`,
      }
    } else {
      ctx.library = {
        name: 'analytics.js',
        version: `npm:next-${version}`,
      }
    }
  }

  if (query && !ctx.campaign) {
    ctx.campaign = utm(query)
  }

  referrerId(query, ctx, analytics.options.disableClientPersistence ?? false)

  json.userId = json.userId || user.id()
  json.anonymousId = json.anonymousId || user.anonymousId()

  json.sentAt = new Date()

  const failed = analytics.queue.failedInitializations || []
  if (failed.length > 0) {
    json._metadata = { failedInitializations: failed }
  }

  const bundled: string[] = []
  const unbundled: string[] = []

  for (const key in integrations) {
    const integration = integrations[key]
    if (key === 'june.so') {
      bundled.push(key)
    }
    if (integration.bundlingStatus === 'bundled') {
      bundled.push(key)
    }
    if (integration.bundlingStatus === 'unbundled') {
      unbundled.push(key)
    }
  }

  // This will make sure that the disabled cloud mode destinations will be
  // included in the unbundled list.
  for (const settingsUnbundled of settings?.unbundledIntegrations || []) {
    if (!unbundled.includes(settingsUnbundled)) {
      unbundled.push(settingsUnbundled)
    }
  }

  const configIds = settings?.maybeBundledConfigIds ?? {}
  const bundledConfigIds: string[] = []

  bundled.sort().forEach((name) => {
    ;(configIds[name] ?? []).forEach((id) => {
      bundledConfigIds.push(id)
    })
  })

  if (settings?.addBundledMetadata !== false) {
    json._metadata = {
      ...json._metadata,
      bundled: bundled.sort(),
      unbundled: unbundled.sort(),
      bundledIds: bundledConfigIds,
    }
  }

  const amp = ampId()
  if (amp) {
    ctx.amp = { id: amp }
  }

  return json
}
