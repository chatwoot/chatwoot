import { PriorityQueue } from '../../lib/priority-queue'
import { PersistedPriorityQueue } from '../../lib/priority-queue/persisted'
import { Context } from '../context'
import { AnyBrowserPlugin } from '../plugin'
import { CoreEventQueue } from '@segment/analytics-core'

export class EventQueue extends CoreEventQueue<Context, AnyBrowserPlugin> {
  constructor(priorityQueue?: PriorityQueue<Context>) {
    super(priorityQueue ?? new PersistedPriorityQueue(4, 'event-queue'))
  }
}
