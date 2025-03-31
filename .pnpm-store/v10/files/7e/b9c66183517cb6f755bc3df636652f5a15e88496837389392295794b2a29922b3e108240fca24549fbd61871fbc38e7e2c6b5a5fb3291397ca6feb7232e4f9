import { Emitter } from '../emitter'
import { backoff } from './backoff'

/**
 * @internal
 */
export const ON_REMOVE_FROM_FUTURE = 'onRemoveFromFuture'

interface QueueItem {
  id: string
}

export class PriorityQueue<Item extends QueueItem = QueueItem> extends Emitter {
  protected future: Item[] = []
  protected queue: Item[]
  protected seen: Record<string, number>

  public maxAttempts: number

  constructor(
    maxAttempts: number,
    queue: Item[],
    seen?: Record<string, number>
  ) {
    super()
    this.maxAttempts = maxAttempts
    this.queue = queue
    this.seen = seen ?? {}
  }

  push(...items: Item[]): boolean[] {
    const accepted = items.map((operation) => {
      const attempts = this.updateAttempts(operation)

      if (attempts > this.maxAttempts || this.includes(operation)) {
        return false
      }

      this.queue.push(operation)
      return true
    })

    this.queue = this.queue.sort(
      (a, b) => this.getAttempts(a) - this.getAttempts(b)
    )
    return accepted
  }

  pushWithBackoff(item: Item): boolean {
    if (this.getAttempts(item) === 0) {
      return this.push(item)[0]
    }

    const attempt = this.updateAttempts(item)

    if (attempt > this.maxAttempts || this.includes(item)) {
      return false
    }

    const timeout = backoff({ attempt: attempt - 1 })

    setTimeout(() => {
      this.queue.push(item)
      // remove from future list
      this.future = this.future.filter((f) => f.id !== item.id)
      // Lets listeners know that a 'future' message is now available in the queue
      this.emit(ON_REMOVE_FROM_FUTURE)
    }, timeout)

    this.future.push(item)
    return true
  }

  public getAttempts(item: Item): number {
    return this.seen[item.id] ?? 0
  }

  public updateAttempts(item: Item): number {
    this.seen[item.id] = this.getAttempts(item) + 1
    return this.getAttempts(item)
  }

  includes(item: Item): boolean {
    return (
      this.queue.includes(item) ||
      this.future.includes(item) ||
      Boolean(this.queue.find((i) => i.id === item.id)) ||
      Boolean(this.future.find((i) => i.id === item.id))
    )
  }

  pop(): Item | undefined {
    return this.queue.shift()
  }

  public get length(): number {
    return this.queue.length
  }

  public get todo(): number {
    return this.queue.length + this.future.length
  }
}
