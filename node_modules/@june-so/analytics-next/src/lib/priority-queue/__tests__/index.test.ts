import { PriorityQueue } from '..'

type Item = {
  id: string
}

describe('RetryQueue', () => {
  it('accepts new work', () => {
    const queue = new PriorityQueue<Item>(10, [])
    queue.push({ id: 'abc' }, { id: 'cde' })
    expect(queue.length).toBe(2)
  })

  it('pops items off the queue', () => {
    const queue = new PriorityQueue<Item>(10, [])
    queue.push({ id: 'abc' }, { id: 'cde' })

    expect(queue.pop()).toEqual({ id: 'abc' })
    expect(queue.length).toBe(1)

    expect(queue.pop()).toEqual({ id: 'cde' })
    expect(queue.length).toBe(0)
  })

  it('deprioritizes repeated items', () => {
    const queue = new PriorityQueue<Item>(10, [])
    queue.push({ id: 'abc' })
    queue.push({ id: 'abc' })

    queue.push({ id: 'cde' })

    // deprioritizes 'abc' because it was seen twice
    expect(queue.pop()).toEqual({ id: 'cde' })
  })

  it('deprioritizes repeated items even though they have been popped before', () => {
    const queue = new PriorityQueue<Item>(10, [])
    queue.push({ id: 'abc' })
    queue.pop()

    queue.push({ id: 'abc' })
    queue.push({ id: 'cde' })

    // a queue does not forget
    expect(queue.pop()).toEqual({ id: 'cde' })
  })

  it('stops accepting an item after attempts have been exausted', () => {
    const queue = new PriorityQueue<Item>(3, [])
    queue.push({ id: 'abc' })
    expect(queue.length).toBe(1)
    queue.pop()

    queue.push({ id: 'abc' })
    expect(queue.length).toBe(1)
    queue.pop()

    queue.push({ id: 'abc' })
    expect(queue.length).toBe(1)
    queue.pop()

    queue.push({ id: 'abc' })
    // does not accept it anymore
    expect(queue.length).toBe(0)
  })
})

describe('backoffs', () => {
  afterEach(() => {
    jest.clearAllTimers()
  })

  it('accepts new work', () => {
    const queue = new PriorityQueue<Item>(10, [])

    queue.pushWithBackoff({ id: 'abc' })
    queue.pushWithBackoff({ id: 'cde' })

    expect(queue.length).toBe(2)
    expect(queue.todo).toBe(2)
  })

  it('ignores when item has not been worked on', () => {
    const queue = new PriorityQueue<Item>(10, [])

    expect(queue.pushWithBackoff({ id: 'abc' })).toBe(true)
    expect(queue.pushWithBackoff({ id: 'abc' })).toBe(false)
    expect(queue.length).toBe(1)
    expect(queue.todo).toBe(1)
  })

  it('schedules as future work when item returns to the queue', () => {
    const queue = new PriorityQueue<Item>(10, [])

    queue.pushWithBackoff({ id: 'abc' })
    queue.pop()

    // accepted work
    expect(queue.pushWithBackoff({ id: 'abc' })).toBe(true)

    // not in the main queue yet
    expect(queue.length).toBe(0)

    // present in future work
    expect(queue.todo).toBe(1)
    expect(queue.includes({ id: 'abc' })).toBe(true)
  })

  it('schedules as future work for later', () => {
    jest.useFakeTimers()
    const spy = jest.spyOn(global, 'setTimeout')

    const queue = new PriorityQueue<Item>(10, [])

    queue.pushWithBackoff({ id: 'abc' })
    expect(spy).not.toHaveBeenCalled()

    queue.pop()

    queue.pushWithBackoff({ id: 'abc' })
    expect(spy).toHaveBeenCalled()

    const delay = spy.mock.calls[0][1]
    expect(delay).toBeGreaterThan(1000)
  })

  it('increases the delay as work gets requeued', () => {
    jest.useFakeTimers()
    const spy = jest.spyOn(global, 'setTimeout')

    const queue = new PriorityQueue<Item>(10, [])

    queue.pushWithBackoff({ id: 'abc' })
    jest.advanceTimersToNextTimer()
    queue.pop()

    queue.pushWithBackoff({ id: 'abc' })
    jest.advanceTimersToNextTimer()
    queue.pop()

    queue.pushWithBackoff({ id: 'abc' })
    jest.advanceTimersToNextTimer()
    queue.pop()

    queue.pushWithBackoff({ id: 'abc' })
    jest.advanceTimersToNextTimer()
    queue.pop()

    const firstDelay = spy.mock.calls[0][1]
    expect(firstDelay).toBeGreaterThan(1000)

    const secondDelay = spy.mock.calls[1][1]
    expect(secondDelay).toBeGreaterThan(2000)

    const thirdDelay = spy.mock.calls[2][1]
    expect(thirdDelay).toBeGreaterThan(3000)
  })
})
