import { Analytics, InitOptions } from '../core/analytics'
import { AnalyticsBrowser } from '.'
import { embeddedWriteKey } from '../lib/embedded-write-key'

export interface AnalyticsSnippet extends AnalyticsStandalone {
  load: (writeKey: string, options?: InitOptions) => void
}

export interface AnalyticsStandalone extends Analytics {
  _loadOptions?: InitOptions
  _writeKey?: string
  _cdn?: string
}

declare global {
  interface Window {
    analytics: AnalyticsSnippet
  }
}

function getWriteKey(): string | undefined {
  if (embeddedWriteKey()) {
    return embeddedWriteKey()
  }

  if (window.analytics._writeKey) {
    return window.analytics._writeKey
  }

  const regex = /http.*\/analytics\.js\/v1\/([^/]*)(\/platform)?\/analytics.*/
  const scripts = Array.prototype.slice.call(
    document.querySelectorAll('script')
  )
  let writeKey: string | undefined = undefined

  for (const s of scripts) {
    const src = s.getAttribute('src') ?? ''
    const result = regex.exec(src)

    if (result && result[1]) {
      writeKey = result[1]
      break
    }
  }

  if (!writeKey && document.currentScript) {
    const script = document.currentScript as HTMLScriptElement
    const src = script.src

    const result = regex.exec(src)

    if (result && result[1]) {
      writeKey = result[1]
    }
  }

  return writeKey
}

export async function install(): Promise<void> {
  const writeKey = getWriteKey()
  const options = window.analytics?._loadOptions ?? {}
  if (!writeKey) {
    console.error(
      'Failed to load Write Key. Make sure to use the latest version of the Segment snippet, which can be found in your source settings.'
    )
    return
  }

  window.analytics = (await AnalyticsBrowser.standalone(
    writeKey,
    options
  )) as AnalyticsSnippet
}
