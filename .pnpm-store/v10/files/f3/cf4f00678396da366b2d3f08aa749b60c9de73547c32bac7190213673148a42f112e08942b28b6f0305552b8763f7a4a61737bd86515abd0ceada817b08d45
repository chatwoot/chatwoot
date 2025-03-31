import { CoreSegmentEvent } from '../events/interfaces'

import { v4 as uuid } from '@lukeed/uuid'
import { dset } from 'dset'
import { CoreLogger, LogLevel, LogMessage } from '../logger'
import { CoreStats, CoreMetric, NullStats } from '../stats'

export interface SerializedContext {
  id: string
  event: CoreSegmentEvent
  logs: LogMessage[]
  metrics?: CoreMetric[]
}

export interface ContextFailedDelivery {
  reason: unknown
}

export interface CancelationOptions {
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

export abstract class CoreContext<
  Event extends CoreSegmentEvent = CoreSegmentEvent
> {
  event: Event
  logger: CoreLogger
  stats: CoreStats
  attempts = 0

  private _failedDelivery?: ContextFailedDelivery
  private _id: string

  constructor(
    event: Event,
    id = uuid(),
    stats: CoreStats = new NullStats(),
    logger = new CoreLogger()
  ) {
    this.event = event
    this._id = id
    this.logger = logger
    this.stats = stats
  }

  static system(): void {
    // This should be overridden by the subclass to return an instance of the subclass.
  }

  isSame(other: CoreContext): boolean {
    return other.id === this.id
  }

  cancel(error?: Error | ContextCancelation): never {
    if (error) {
      throw error
    }

    throw new ContextCancelation({ reason: 'Context Cancel' })
  }

  log(level: LogLevel, message: string, extras?: object): void {
    this.logger.log(level, message, extras)
  }

  get id(): string {
    return this._id
  }

  updateEvent(path: string, val: unknown): Event {
    // Don't allow integrations that are set to false to be overwritten with integration settings.
    if (path.split('.')[0] === 'integrations') {
      const integrationName = path.split('.')[1]

      if (this.event.integrations?.[integrationName] === false) {
        return this.event
      }
    }

    dset(this.event, path, val)
    return this.event
  }

  failedDelivery(): ContextFailedDelivery | undefined {
    return this._failedDelivery
  }

  setFailedDelivery(options: ContextFailedDelivery) {
    this._failedDelivery = options
  }

  logs(): LogMessage[] {
    return this.logger.logs
  }

  flush(): void {
    this.logger.flush()
    this.stats.flush()
  }

  toJSON(): SerializedContext {
    return {
      id: this._id,
      event: this.event,
      logs: this.logger.logs,
      metrics: this.stats.metrics,
    }
  }
}
