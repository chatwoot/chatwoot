/* eslint-disable @typescript-eslint/no-floating-promises */
import { Analytics } from '../../../analytics'
import { pWhile } from '../../../lib/p-while'
import * as timer from '../../../lib/priority-queue/backoff'
import {
  MiddlewareFunction,
  sourceMiddlewarePlugin,
} from '../../../plugins/middleware'
import { Context, ContextCancelation } from '../../context'
import { Plugin } from '../../plugin'
import { EventQueue } from '../event-queue'

async function flushAll(eq: EventQueue): Promise<Context[]> {
  let flushed: Context[] = []

  await pWhile(
    () => eq.queue.length > 0,
    async () => {
      const res = await eq.flush().catch(() => [])
      flushed = flushed.concat(res)
    }
  )
  return flushed
}

const testPlugin: Plugin = {
  name: 'test',
  type: 'before',
  version: '0.1.0',
  load: () => Promise.resolve(),
  isLoaded: () => true,
}

const ajs = {} as Analytics

let fruitBasket: Context, basketView: Context, shopper: Context

beforeEach(() => {
  fruitBasket = new Context({
    type: 'track',
    event: 'Fruit Basket',
    properties: {
      banana: '🍌',
      apple: '🍎',
      grape: '🍇',
    },
  })

  basketView = new Context({
    type: 'page',
  })

  shopper = new Context({
    type: 'identify',
    traits: {
      name: 'Netto Farah',
    },
  })
})

test('can send events', async () => {
  const eq = new EventQueue()
  const evt = await eq.dispatch(fruitBasket)
  expect(evt).toBe(fruitBasket)
})

test('delivers events out of band', async () => {
  jest.useFakeTimers()

  const eq = new EventQueue()

  // eslint-disable-next-line @typescript-eslint/no-floating-promises
  eq.dispatch(fruitBasket)

  expect(setTimeout).toHaveBeenCalled()
  expect(eq.queue.includes(fruitBasket)).toBe(true)

  // run timers and deliver events
  jest.runAllTimers()
  await eq.flush()

  expect(eq.queue.length).toBe(0)
})

test('does not enqueue multiple flushes at once', async () => {
  jest.useFakeTimers()

  const eq = new EventQueue()

  const anothaOne = new Context({
    type: 'page',
  })

  eq.dispatch(fruitBasket)
  eq.dispatch(anothaOne)

  expect(setTimeout).toHaveBeenCalledTimes(1)
  expect(eq.queue.length).toBe(2)

  jest.useRealTimers()
  await flushAll(eq)

  expect(eq.queue.length).toBe(0)
})

describe('Flushing', () => {
  beforeEach(() => {
    jest.useRealTimers()
  })

  test('works until the queue is empty', async () => {
    const eq = new EventQueue()

    eq.dispatch(fruitBasket)
    eq.dispatch(basketView)
    eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    const flushed = await flushAll(eq)

    expect(eq.queue.length).toBe(0)
    expect(flushed).toEqual([fruitBasket, basketView, shopper])
  })

  test('re-queues failed events', async () => {
    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: (ctx) => {
          if (ctx === fruitBasket) {
            throw new Error('aaay')
          }

          return Promise.resolve(ctx)
        },
      },
      ajs
    )

    eq.dispatch(fruitBasket)
    eq.dispatch(basketView)
    eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    const flushed = await flushAll(eq)

    // flushed good events
    expect(flushed).toEqual([basketView, shopper])

    // attempted to deliver multiple times
    expect(eq.queue.getAttempts(fruitBasket)).toEqual(2)
  })

  test('delivers events on retry', async () => {
    jest.useRealTimers()

    // make sure all backoffs return immediatelly
    jest.spyOn(timer, 'backoff').mockImplementationOnce(() => 100)

    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: (ctx) => {
          // only fail first attempt
          if (ctx === fruitBasket && ctx.attempts === 1) {
            throw new Error('aaay')
          }

          return Promise.resolve(ctx)
        },
      },
      ajs
    )

    eq.dispatch(fruitBasket)
    eq.dispatch(basketView)
    eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    let flushed = await flushAll(eq)
    // delivered both basket and shopper
    expect(flushed).toEqual([basketView, shopper])

    // wait for the exponential backoff
    await new Promise((res) => setTimeout(res, 100))

    // second try
    flushed = await flushAll(eq)
    expect(eq.queue.length).toBe(0)

    expect(flushed).toEqual([fruitBasket])
    expect(flushed[0].attempts).toEqual(2)
  })

  test('does not retry non retriable cancelations', async () => {
    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: async (ctx) => {
          if (ctx === fruitBasket) {
            throw new ContextCancelation({ retry: false, reason: 'Test!' })
          }
          return ctx
        },
      },
      ajs
    )

    eq.dispatch(fruitBasket)
    eq.dispatch(basketView)
    eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    const flushed = await flushAll(eq)
    // delivered both basket and shopper
    expect(flushed).toEqual([basketView, shopper])

    // nothing to retry
    expect(eq.queue.length).toBe(0)
  })

  test('retries retriable cancelations', async () => {
    // make sure all backoffs return immediatelly
    jest.spyOn(timer, 'backoff').mockImplementationOnce(() => 100)

    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: (ctx) => {
          // only fail first attempt
          if (ctx === fruitBasket && ctx.attempts === 1) {
            ctx.cancel(new ContextCancelation({ retry: true }))
          }

          return Promise.resolve(ctx)
        },
      },
      ajs
    )

    eq.dispatch(fruitBasket)
    eq.dispatch(basketView)
    eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    let flushed = await flushAll(eq)
    // delivered both basket and shopper
    expect(flushed).toEqual([basketView, shopper])

    // wait for the exponential backoff
    await new Promise((res) => setTimeout(res, 100))

    // second try
    flushed = await flushAll(eq)
    expect(eq.queue.length).toBe(0)

    expect(flushed).toEqual([fruitBasket])
    expect(flushed[0].attempts).toEqual(2)
  })

  test('client: can block on delivery', async () => {
    jest.useRealTimers()
    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: (ctx) => {
          // only fail first attempt
          if (ctx === fruitBasket && ctx.attempts === 1) {
            throw new Error('aaay')
          }

          return Promise.resolve(ctx)
        },
      },
      ajs
    )

    const fruitBasketDelivery = eq.dispatch(fruitBasket)
    const basketViewDelivery = eq.dispatch(basketView)
    const shopperDelivery = eq.dispatch(shopper)

    expect(eq.queue.length).toBe(3)

    const [fruitBasketCtx, basketViewCtx, shopperCtx] = await Promise.all([
      fruitBasketDelivery,
      basketViewDelivery,
      shopperDelivery,
    ])

    expect(eq.queue.length).toBe(0)

    expect(fruitBasketCtx.attempts).toBe(2)
    expect(basketViewCtx.attempts).toBe(1)
    expect(shopperCtx.attempts).toBe(1)
  })

  describe('denyList permutations', () => {
    const amplitude = {
      ...testPlugin,
      name: 'Amplitude',
      type: 'destination' as const,
      track: (ctx: Context): Promise<Context> | Context => {
        return Promise.resolve(ctx)
      },
    }

    const mixPanel = {
      ...testPlugin,
      name: 'Mixpanel',
      type: 'destination' as const,
      track: (ctx: Context): Promise<Context> | Context => {
        return Promise.resolve(ctx)
      },
    }

    test('does not delivery to destinations on denyList', async () => {
      const eq = new EventQueue()

      jest.spyOn(amplitude, 'track')
      jest.spyOn(mixPanel, 'track')

      const evt = {
        type: 'track' as const,
        integrations: {
          Mixpanel: false,
        },
      }

      const ctx = new Context(evt)

      await eq.register(Context.system(), amplitude, ajs)
      await eq.register(Context.system(), mixPanel, ajs)

      eq.dispatch(ctx)

      expect(eq.queue.length).toBe(1)

      const flushed = await flushAll(eq)

      expect(flushed).toEqual([ctx])

      expect(mixPanel.track).not.toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
    })

    test('does not deliver to any destination if All: false ', async () => {
      const eq = new EventQueue()

      jest.spyOn(amplitude, 'track')
      jest.spyOn(mixPanel, 'track')

      const evt = {
        type: 'track' as const,
        integrations: {
          All: false,
        },
      }

      const ctx = new Context(evt)

      await eq.register(Context.system(), amplitude, ajs)
      await eq.register(Context.system(), mixPanel, ajs)

      eq.dispatch(ctx)

      expect(eq.queue.length).toBe(1)
      const flushed = await flushAll(eq)

      expect(flushed).toEqual([ctx])

      expect(mixPanel.track).not.toHaveBeenCalled()
      expect(amplitude.track).not.toHaveBeenCalled()
    })

    test('delivers to destinations if All: false but the destination is allowed', async () => {
      const eq = new EventQueue()

      jest.spyOn(amplitude, 'track')
      jest.spyOn(mixPanel, 'track')

      const evt = {
        type: 'track' as const,
        integrations: {
          All: false,
          Amplitude: true,
        },
      }

      const ctx = new Context(evt)

      await eq.register(Context.system(), amplitude, ajs)
      await eq.register(Context.system(), mixPanel, ajs)

      eq.dispatch(ctx)

      expect(eq.queue.length).toBe(1)
      const flushed = await flushAll(eq)

      expect(flushed).toEqual([ctx])

      expect(mixPanel.track).not.toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
    })

    test('delivers to destinations that exist as an object', async () => {
      const eq = new EventQueue()

      jest.spyOn(amplitude, 'track')

      const evt = {
        type: 'track' as const,
        integrations: {
          All: false,
          Amplitude: {
            amplitudeKey: 'foo',
          },
        },
      }

      const ctx = new Context(evt)

      await eq.register(Context.system(), amplitude, ajs)

      eq.dispatch(ctx)

      expect(eq.queue.length).toBe(1)
      const flushed = await flushAll(eq)

      expect(flushed).toEqual([ctx])

      expect(amplitude.track).toHaveBeenCalled()
    })

    test('respect deny lists generated by other plugin', async () => {
      const eq = new EventQueue()

      jest.spyOn(amplitude, 'track')
      jest.spyOn(mixPanel, 'track')

      const evt = {
        type: 'track' as const,
        integrations: {
          Amplitude: true,
          MixPanel: true,
        },
      }

      const ctx = new Context(evt)
      await eq.register(Context.system(), amplitude, ajs)
      await eq.register(Context.system(), mixPanel, ajs)
      await eq.dispatch(ctx)

      const skipAmplitude: MiddlewareFunction = ({ payload, next }) => {
        if (!payload.obj.integrations) {
          payload.obj.integrations = {}
        }

        payload.obj.integrations['Amplitude'] = false
        next(payload)
      }

      await eq.register(
        Context.system(),
        sourceMiddlewarePlugin(skipAmplitude, {}),
        ajs
      )

      await eq.dispatch(ctx)

      expect(mixPanel.track).toHaveBeenCalledTimes(2)
      expect(amplitude.track).toHaveBeenCalledTimes(1)
    })
  })
})

describe('deregister', () => {
  it('remove plugin from plugins list', async () => {
    const eq = new EventQueue()
    const toBeRemoved = { ...testPlugin, name: 'remove-me' }
    const plugins = [testPlugin, toBeRemoved]

    const promises = plugins.map((p) => eq.register(Context.system(), p, ajs))
    await Promise.all(promises)

    await eq.deregister(Context.system(), toBeRemoved, ajs)
    expect(eq.plugins.length).toBe(1)
    expect(eq.plugins[0]).toBe(testPlugin)
  })

  it('invokes plugin.unload', async () => {
    const eq = new EventQueue()
    const toBeRemoved = { ...testPlugin, name: 'remove-me', unload: jest.fn() }
    const plugins = [testPlugin, toBeRemoved]

    const promises = plugins.map((p) => eq.register(Context.system(), p, ajs))
    await Promise.all(promises)

    await eq.deregister(Context.system(), toBeRemoved, ajs)
    expect(toBeRemoved.unload).toHaveBeenCalled()
    expect(eq.plugins.length).toBe(1)
    expect(eq.plugins[0]).toBe(testPlugin)
  })
})

describe('dispatchSingle', () => {
  it('dispatches events without placing them on the queue', async () => {
    const eq = new EventQueue()
    const promise = eq.dispatchSingle(fruitBasket)

    expect(eq.queue.length).toBe(0)
    await promise
    expect(eq.queue.length).toBe(0)
  })

  it('records delivery metrics', async () => {
    const eq = new EventQueue()
    const ctx = await eq.dispatchSingle(
      new Context({
        type: 'track',
      })
    )

    expect(ctx.logs().map((l) => l.message)).toMatchInlineSnapshot(`
      Array [
        "Dispatching",
        "Delivered",
      ]
    `)

    expect(ctx.stats.metrics.map((m) => m.metric)).toMatchInlineSnapshot(`
      Array [
        "message_dispatched",
        "message_delivered",
        "delivered",
      ]
    `)
  })

  test('retries retriable cancelations', async () => {
    // make sure all backoffs return immediatelly
    jest.spyOn(timer, 'backoff').mockImplementationOnce(() => 100)

    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        track: (ctx) => {
          // only fail first attempt
          if (ctx === fruitBasket && ctx.attempts === 1) {
            ctx.cancel(new ContextCancelation({ retry: true }))
          }

          return Promise.resolve(ctx)
        },
      },
      ajs
    )

    expect(eq.queue.length).toBe(0)

    const attempted = await eq.dispatchSingle(fruitBasket)
    expect(attempted.attempts).toEqual(2)
  })
})
