import { v4 as uuid } from '@lukeed/uuid'
import { dset } from 'dset'
import { SegmentEvent } from '../events'
import Logger, { LogLevel, LogMessage } from '../logger'
import Stats, { Metric } from '../stats'
import { MetricsOptions, RemoteMetrics } from '../stats/remote-metrics'

export interface AbstractContext {
  cancel: () => never
  log: (level: LogLevel, message: string, extras?: object) => void
  stats: Stats
}

export interface SerializedContext {
  id: string
  event: SegmentEvent
  logs: LogMessage[]
  metrics: Metric[]
}

interface CancelationOptions {
  retry?: boolean
  reason?: string
  type?: string
}

export class ContextCancelation {
  retry: boolean
  type: string
  reason?: string

  constructor(options: CancelationOptions) {
    this.retry = options.retry ?? true
    this.type = options.type ?? 'plugin Error'
    this.reason = options.reason ?? ''
  }
}

let remoteMetrics: RemoteMetrics | undefined

export class Context implements AbstractContext {
  private _event: SegmentEvent
  private _attempts: number
  public logger = new Logger()
  public stats: Stats
  private _id: string

  constructor(event: SegmentEvent, id?: string) {
    this._attempts = 0
    this._event = event
    this._id = id ?? uuid()
    this.stats = new Stats(remoteMetrics)
  }

  static initMetrics(options?: MetricsOptions): void {
    remoteMetrics = new RemoteMetrics(options)
  }

  static system(): Context {
    return new Context({ type: 'track', event: 'system' })
  }

  isSame(other: Context): boolean {
    return other._id === this._id
  }

  cancel = (error?: Error | ContextCancelation): never => {
    if (error) {
      throw error
    }

    throw new ContextCancelation({ reason: 'Context Cancel' })
  }

  log(level: LogLevel, message: string, extras?: object): void {
    this.logger.log(level, message, extras)
  }

  public get id(): string {
    return this._id
  }

  public get event(): SegmentEvent {
    return this._event
  }

  public set event(evt: SegmentEvent) {
    this._event = evt
  }

  public get attempts(): number {
    return this._attempts
  }

  public set attempts(attempts: number) {
    this._attempts = attempts
  }

  public updateEvent(path: string, val: unknown): SegmentEvent {
    // Don't allow integrations that are set to false to be overwritten with integration settings.
    if (path.split('.')[0] === 'integrations') {
      const integrationName = path.split('.')[1]

      if (this._event.integrations?.[integrationName] === false) {
        return this._event
      }
    }

    dset(this._event, path, val)
    return this._event
  }

  public logs(): LogMessage[] {
    return this.logger.logs
  }

  public flush(): void {
    this.logger.flush()
    this.stats.flush()
  }

  toJSON(): SerializedContext {
    return {
      id: this._id,
      event: this._event,
      logs: this.logger.logs,
      metrics: this.stats.metrics,
    }
  }
}
