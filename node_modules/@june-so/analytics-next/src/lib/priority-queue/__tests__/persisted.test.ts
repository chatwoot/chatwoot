import { Context } from '../../../core/context'
import { PersistedPriorityQueue } from '../persisted'

describe('Persisted Priority Queue', () => {
  beforeEach(() => {
    window.localStorage.clear()
  })

  const key = 'event-queue'

  it('a queue remembers', () => {
    const ctx = new Context(
      {
        type: 'track',
        properties: {
          banana: '🍌',
        },
      },
      'abc'
    )

    window.localStorage.setItem(
      `persisted-queue:v1:${key}:items`,
      JSON.stringify([ctx])
    )
    window.localStorage.setItem(
      `persisted-queue:v1:${key}:seen`,
      JSON.stringify({ abc: 2 })
    )

    const queue = new PersistedPriorityQueue(3, key)
    const included = queue.includes(ctx)

    expect(included).toBe(true)
    expect(queue.todo).toBe(1)
    expect(queue.getAttempts(ctx)).toBe(2)
  })

  it('a queue always pays their debts', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let onUnload: any = jest.fn()

    jest
      .spyOn(window, 'addEventListener')
      .mockImplementation((evt, handler) => {
        if (evt === 'beforeunload') {
          onUnload = handler
        }
      })

    const ctx = new Context(
      {
        type: 'track',
        properties: {
          banana: '🍌',
        },
      },
      'abc'
    )

    const queue = new PersistedPriorityQueue(3, key)
    queue.push(ctx)

    onUnload()

    const items = JSON.parse(
      localStorage.getItem(`persisted-queue:v1:${key}:items`) ?? ''
    )
    const seen = JSON.parse(
      localStorage.getItem(`persisted-queue:v1:${key}:seen`) ?? ''
    )

    expect(items[0]).toEqual(ctx.toJSON())
    expect(seen).toEqual({ abc: 1 })
  })

  it('a queue has a name', () => {
    const ctx = new Context(
      {
        type: 'track',
        properties: {
          banana: '🍌',
        },
      },
      'abc'
    )
    window.localStorage.setItem(
      `persisted-queue:v1:different-key:items`,
      JSON.stringify([ctx])
    )

    const queue = new PersistedPriorityQueue(3, key)
    expect(queue.todo).toBe(0)

    const correctQueue = new PersistedPriorityQueue(3, 'different-key')
    expect(correctQueue.todo).toBe(1)
  })

  describe('merging', () => {
    it('merges queue items with existing data', () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let onUnload: any = jest.fn()

      jest
        .spyOn(window, 'addEventListener')
        .mockImplementation((evt, handler) => {
          if (evt === 'beforeunload') {
            onUnload = handler
          }
        })

      const ctx = new Context(
        {
          type: 'track',
          properties: {
            banana: '🍌',
          },
        },
        'abc'
      )

      window.localStorage.setItem(
        `persisted-queue:v1:${key}:items`,
        JSON.stringify([ctx])
      )

      const ctxFromDifferentTab = new Context(
        {
          type: 'page',
          properties: {
            banana: '🍌',
          },
        },
        'cde'
      )

      const queue = new PersistedPriorityQueue(3, key)

      expect(queue.includes(ctx)).toBe(true)
      expect(queue.includes(ctxFromDifferentTab)).not.toBe(true)

      // another tab sets these two events again
      window.localStorage.setItem(
        `persisted-queue:v1:${key}:items`,
        JSON.stringify([ctx, ctxFromDifferentTab])
      )

      const newCtx = new Context(
        {
          type: 'identify',
        },
        'id'
      )

      expect(queue.push(newCtx)).toEqual([true])

      // page is unloaded
      onUnload()

      const persisted = JSON.parse(
        window.localStorage.getItem(`persisted-queue:v1:${key}:items`) ?? ''
      ) as unknown[]

      expect(persisted.length).toBe(3)
      expect(persisted).toContainEqual(ctx.toJSON())
      expect(persisted).toContainEqual(ctxFromDifferentTab.toJSON())
      expect(persisted).toContainEqual(newCtx.toJSON())
    })
  })

  describe('concurrency', () => {
    it('only one tab unloads items from localstorage', () => {
      const ctx = new Context(
        {
          type: 'track',
          properties: {
            banana: '🍌',
          },
        },
        'abc'
      )

      window.localStorage.setItem(
        `persisted-queue:v1:${key}:items`,
        JSON.stringify([ctx])
      )

      const firstTabQueue = new PersistedPriorityQueue(3, key)
      const secondTabQueue = new PersistedPriorityQueue(3, key)

      // first tab gets a hold of it
      expect(firstTabQueue.includes(ctx)).toBe(true)

      // it's gone by the time the second tab comes in
      expect(secondTabQueue.includes(ctx)).not.toBe(true)
    })

    it('does not allow multiple tabs to override each other when closed', () => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const onUnloadFunctions: any[] = []

      jest
        .spyOn(window, 'addEventListener')
        .mockImplementation((evt, handler) => {
          if (evt === 'beforeunload') {
            onUnloadFunctions.push(handler)
          }
        })

      const firstTabQueue = new PersistedPriorityQueue(3, key)
      const secondTabQueue = new PersistedPriorityQueue(3, key)

      const firstTabItem = new Context({ type: 'track' }, 'firstTab')
      const secondTabItem = new Context({ type: 'page' }, 'secondTab')

      firstTabQueue.push(firstTabItem)
      secondTabQueue.push(secondTabItem)

      onUnloadFunctions[1]()
      onUnloadFunctions[0]()

      const stored = JSON.parse(
        window.localStorage.getItem(`persisted-queue:v1:${key}:items`) ?? ''
      )
      expect(stored.length).toBe(2)
    })
  })
})
