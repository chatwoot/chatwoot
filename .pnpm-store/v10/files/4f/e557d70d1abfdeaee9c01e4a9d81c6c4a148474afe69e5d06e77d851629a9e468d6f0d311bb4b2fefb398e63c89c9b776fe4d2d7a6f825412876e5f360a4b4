import { fetch } from '../../lib/fetch'
import { version } from '../../generated/version'
import { getVersionType } from '../../plugins/segmentio/normalize'

export interface MetricsOptions {
  host?: string
  sampleRate?: number
  flushTimer?: number
  maxQueueSize?: number
}

/**
 * Type expected by the segment metrics API endpoint
 */
type RemoteMetric = {
  type: 'Counter'
  metric: string
  value: 1
  tags: {
    library: string
    library_version: string
    [key: string]: string
  }
}

const createRemoteMetric = (
  metric: string,
  tags: string[],
  versionType: 'web' | 'npm'
): RemoteMetric => {
  const formattedTags = tags.reduce((acc, t) => {
    const [k, v] = t.split(':')
    acc[k] = v
    return acc
  }, {} as Record<string, string>)

  return {
    type: 'Counter',
    metric,
    value: 1,
    tags: {
      ...formattedTags,
      library: 'analytics.js',
      library_version:
        versionType === 'web' ? `next-${version}` : `npm:next-${version}`,
    },
  }
}

function logError(err: unknown): void {
  console.error('Error sending segment performance metrics', err)
}

export class RemoteMetrics {
  private host: string
  private flushTimer: number
  private maxQueueSize: number

  sampleRate: number
  queue: RemoteMetric[]

  constructor(options?: MetricsOptions) {
    this.host = options?.host ?? 'api.june.so/sdk'
    this.sampleRate = options?.sampleRate ?? 1
    this.flushTimer = options?.flushTimer ?? 30 * 1000 /* 30s */
    this.maxQueueSize = options?.maxQueueSize ?? 20

    this.queue = []

    if (this.sampleRate > 0) {
      let flushing = false

      const run = (): void => {
        if (flushing) {
          return
        }

        flushing = true
        this.flush().catch(logError)

        flushing = false

        setTimeout(run, this.flushTimer)
      }
      run()
    }
  }

  increment(metric: string, tags: string[]): void {
    // All metrics are part of an allow list in Tracking API
    if (!metric.includes('analytics_js.')) {
      return
    }

    // /m doesn't like empty tags
    if (tags.length === 0) {
      return
    }

    if (Math.random() > this.sampleRate) {
      return
    }

    if (this.queue.length >= this.maxQueueSize) {
      return
    }

    const remoteMetric = createRemoteMetric(metric, tags, getVersionType())
    this.queue.push(remoteMetric)

    if (metric.includes('error')) {
      this.flush().catch(logError)
    }
  }

  async flush(): Promise<void> {
    if (this.queue.length <= 0) {
      return
    }

    await this.send().catch((error) => {
      logError(error)
      this.sampleRate = 0
    })
  }

  private async send(): Promise<Response> {
    const payload = { series: this.queue }
    this.queue = []

    const headers = { 'Content-Type': 'text/plain' }
    const url = `https://${this.host}/m`

    return fetch(url, {
      headers,
      body: JSON.stringify(payload),
      method: 'POST',
    })
  }
}
