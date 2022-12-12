import { loadScript } from './load-script'
import { getLegacyAJSPath } from './parse-cdn'

let ajsIdentifiedCSP = false

export async function onCSPError(
  e: SecurityPolicyViolationEvent & { disposition?: 'enforce' | 'report' }
): Promise<void> {
  if (e.disposition === 'report') {
    return
  }

  if (!e.blockedURI.includes('cdn.segment') || ajsIdentifiedCSP) {
    return
  }

  ajsIdentifiedCSP = true

  console.warn(
    'Your CSP policy is missing permissions required in order to run Analytics.js 2.0'
  )
  console.warn('Reverting to Analytics.js 1.0')

  const classicPath = getLegacyAJSPath()
  await loadScript(classicPath)
}
