import { RemoteMetrics } from './remote-metrics'

type MetricType = 'gauge' | 'counter'
type CompactMetricType = 'g' | 'c'

export interface Metric {
  metric: string
  value: number
  type: MetricType
  tags: string[]
  timestamp: number // unit milliseconds
}

export interface CompactMetric {
  m: string // metric name
  v: number // value
  k: CompactMetricType
  t: string[] // tags
  e: number // timestamp in unit milliseconds
}

const compactMetricType = (type: MetricType): CompactMetricType => {
  const enums: Record<MetricType, CompactMetricType> = {
    gauge: 'g',
    counter: 'c',
  }
  return enums[type]
}

export default class Stats {
  metrics: Metric[] = []

  private remoteMetrics?: RemoteMetrics

  constructor(remoteMetrics?: RemoteMetrics) {
    this.remoteMetrics = remoteMetrics
  }

  increment(metric: string, by = 1, tags?: string[]): void {
    this.metrics.push({
      metric,
      value: by,
      tags: tags ?? [],
      type: 'counter',
      timestamp: Date.now(),
    })

    this.remoteMetrics?.increment(metric, tags ?? [])
  }

  gauge(metric: string, value: number, tags?: string[]): void {
    this.metrics.push({
      metric,
      value,
      tags: tags ?? [],
      type: 'gauge',
      timestamp: Date.now(),
    })
  }

  flush(): void {
    const formatted = this.metrics.map((m) => ({
      ...m,
      tags: m.tags.join(','),
    }))
    // ie doesn't like console.table
    if (console.table) {
      console.table(formatted)
    } else {
      console.log(formatted)
    }
    this.metrics = []
  }

  /**
   * compact keys for smaller payload
   */
  serialize(): CompactMetric[] {
    return this.metrics.map((m) => {
      return {
        m: m.metric,
        v: m.value,
        t: m.tags,
        k: compactMetricType(m.type),
        e: m.timestamp,
      }
    })
  }
}
