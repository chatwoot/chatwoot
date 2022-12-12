import { PriorityQueue } from '.'
import { Context, SerializedContext } from '../../core/context'
import { isBrowser } from '../../core/environment'

let loc:
  | Storage
  | { getItem: () => void; setItem: () => void; removeItem: () => void } = {
  getItem() {},
  setItem() {},
  removeItem() {},
}

try {
  loc = isBrowser() && window.localStorage ? window.localStorage : loc
} catch (err) {
  console.warn('Unable to access localStorage', err)
}

function persisted(key: string): Context[] {
  const items = loc.getItem(key)
  return (items ? JSON.parse(items) : []).map(
    (p: SerializedContext) => new Context(p.event, p.id)
  )
}

function persistItems(key: string, items: Context[]): void {
  const existing = persisted(key)
  const all = [...items, ...existing]

  const merged = all.reduce((acc, item) => {
    return {
      ...acc,
      [item.id]: item,
    }
  }, {} as Record<string, Context>)

  loc.setItem(key, JSON.stringify(Object.values(merged)))
}

function seen(key: string): Record<string, number> {
  const stored = loc.getItem(key)
  return stored ? JSON.parse(stored) : {}
}

function persistSeen(key: string, memory: Record<string, number>): void {
  const stored = seen(key)

  loc.setItem(
    key,
    JSON.stringify({
      ...stored,
      ...memory,
    })
  )
}

function remove(key: string): void {
  loc.removeItem(key)
}

const now = (): number => new Date().getTime()

function mutex(key: string, onUnlock: Function, attempt = 0): void {
  const lockTimeout = 50
  const lockKey = `persisted-queue:v1:${key}:lock`

  const expired = (lock: number): boolean => new Date().getTime() > lock
  const rawLock = loc.getItem(lockKey)
  const lock = rawLock ? (JSON.parse(rawLock) as number) : null

  const allowed = lock === null || expired(lock)
  if (allowed) {
    loc.setItem(lockKey, JSON.stringify(now() + lockTimeout))
    onUnlock()
    loc.removeItem(lockKey)
    return
  }

  if (!allowed && attempt < 3) {
    setTimeout(() => {
      mutex(key, onUnlock, attempt + 1)
    }, lockTimeout)
  } else {
    throw new Error('Unable to retrieve lock')
  }
}

export class PersistedPriorityQueue extends PriorityQueue<Context> {
  constructor(maxAttempts: number, key: string) {
    super(maxAttempts, [])

    const itemsKey = `persisted-queue:v1:${key}:items`
    const seenKey = `persisted-queue:v1:${key}:seen`

    let saved: Context[] = []
    let lastSeen: Record<string, number> = {}

    mutex(key, () => {
      try {
        saved = persisted(itemsKey)
        lastSeen = seen(seenKey)
        remove(itemsKey)
        remove(seenKey)

        this.queue = [...saved, ...this.queue]
        this.seen = { ...lastSeen, ...this.seen }
      } catch (err) {
        console.error(err)
      }
    })

    window.addEventListener('beforeunload', () => {
      if (this.todo > 0) {
        const items = [...this.queue, ...this.future]
        try {
          mutex(key, () => {
            persistItems(itemsKey, items)
            persistSeen(seenKey, this.seen)
          })
        } catch (err) {
          console.error(err)
        }
      }
    })
  }
}
