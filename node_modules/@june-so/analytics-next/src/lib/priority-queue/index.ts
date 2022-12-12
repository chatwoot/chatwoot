import { backoff } from './backoff'

export type WithID = {
  id: string
}

export class PriorityQueue<T extends WithID> {
  protected future: T[] = []
  protected queue: T[]
  protected seen: Record<string, number>

  public maxAttempts: number

  constructor(maxAttempts: number, queue: T[], seen?: Record<string, number>) {
    this.maxAttempts = maxAttempts
    this.queue = queue
    this.seen = seen ?? {}
  }

  push(...operations: T[]): boolean[] {
    const accepted = operations.map((operation) => {
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

  pushWithBackoff(operation: T): boolean {
    if (this.getAttempts(operation) === 0) {
      return this.push(operation)[0]
    }

    const attempt = this.updateAttempts(operation)

    if (attempt > this.maxAttempts || this.includes(operation)) {
      return false
    }

    const timeout = backoff({ attempt: attempt - 1 })

    setTimeout(() => {
      this.queue.push(operation)
      // remove from future list
      this.future = this.future.filter((f) => f.id !== operation.id)
    }, timeout)

    this.future.push(operation)
    return true
  }

  public getAttempts(operation: T): number {
    return this.seen[operation.id] ?? 0
  }

  public updateAttempts(operation: T): number {
    this.seen[operation.id] = this.getAttempts(operation) + 1
    return this.getAttempts(operation)
  }

  includes(operation: T): boolean {
    return (
      this.queue.includes(operation) ||
      this.future.includes(operation) ||
      Boolean(this.queue.find((i) => i.id === operation.id)) ||
      Boolean(this.future.find((i) => i.id === operation.id))
    )
  }

  pop(): T | undefined {
    return this.queue.shift()
  }

  public get length(): number {
    return this.queue.length
  }

  public get todo(): number {
    return this.queue.length + this.future.length
  }
}
