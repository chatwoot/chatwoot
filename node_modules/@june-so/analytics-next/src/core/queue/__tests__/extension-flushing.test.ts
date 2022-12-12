import { shuffle } from 'lodash'
import { Analytics } from '../../../analytics'
import { PriorityQueue } from '../../../lib/priority-queue'
import { Context } from '../../context'
import { Plugin } from '../../plugin'
import { EventQueue } from '../event-queue'

const fruitBasket = new Context({
  type: 'track',
  event: 'Fruit Basket',
  properties: {
    banana: '🍌',
    apple: '🍎',
    grape: '🍇',
  },
})

const testPlugin: Plugin = {
  name: 'test',
  type: 'before',
  version: '0.1.0',
  load: () => Promise.resolve(),
  isLoaded: () => true,
}

const ajs = {} as Analytics

describe('Registration', () => {
  test('can register plugins', async () => {
    const eq = new EventQueue()
    const load = jest.fn()

    const plugin: Plugin = {
      name: 'test',
      type: 'before',
      version: '0.1.0',
      load,
      isLoaded: () => true,
    }

    const ctx = Context.system()
    await eq.register(ctx, plugin, ajs)

    expect(load).toHaveBeenCalledWith(ctx, ajs)
  })

  test('fails if plugin cant be loaded', async () => {
    const eq = new EventQueue()

    const plugin: Plugin = {
      name: 'test',
      type: 'before',
      version: '0.1.0',
      load: () => Promise.reject(new Error('👻')),
      isLoaded: () => false,
    }

    const ctx = Context.system()
    await expect(
      eq.register(ctx, plugin, ajs)
    ).rejects.toThrowErrorMatchingInlineSnapshot(`"👻"`)
  })

  test('allows for destinations to fail registration', async () => {
    const eq = new EventQueue()

    const plugin: Plugin = {
      name: 'test',
      type: 'destination',
      version: '0.1.0',
      load: () => Promise.reject(new Error('👻')),
      isLoaded: () => false,
    }

    const ctx = Context.system()
    await eq.register(ctx, plugin, ajs)

    expect(ctx.logs()[0].level).toEqual('warn')
    expect(ctx.logs()[0].message).toEqual('Failed to load destination')
  })
})

describe('Plugin flushing', () => {
  test('ensures `before` plugins are run', async () => {
    const eq = new EventQueue()
    const queue = new PriorityQueue(1, [])

    eq.queue = queue

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        type: 'before',
      },
      ajs
    )

    const flushed = await eq.dispatch(fruitBasket)
    expect(flushed.logs().map((l) => l.message)).toContain('Delivered')

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        name: 'Faulty before',
        type: 'before',
        track: () => {
          throw new Error('aaay')
        },
      },
      ajs
    )

    const failedFlush: Context = await eq
      .dispatch(
        new Context({
          type: 'track',
        })
      )
      .catch((ctx) => ctx)

    const messages = failedFlush.logs().map((l) => l.message)
    expect(messages).not.toContain('Delivered')
  })

  test('atempts `enrichment` plugins', async () => {
    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        name: 'Faulty enrichment',
        type: 'enrichment',
        track: () => {
          throw new Error('aaay')
        },
      },
      ajs
    )

    const flushed = await eq.dispatch(
      new Context({
        type: 'track',
      })
    )

    const messages = flushed.logs().map((l) => l.message)
    expect(messages).toContain('Delivered')
  })

  test('attempts `destination` plugins', async () => {
    const eq = new EventQueue()

    const amplitude: Plugin = {
      ...testPlugin,
      name: 'Amplitude',
      type: 'destination',
      track: async () => {
        throw new Error('Boom!')
      },
    }

    const fullstory: Plugin = {
      ...testPlugin,
      name: 'FullStory',
      type: 'destination',
    }

    await eq.register(Context.system(), amplitude, ajs)
    await eq.register(Context.system(), fullstory, ajs)

    const flushed = await eq.dispatch(
      new Context({
        type: 'track',
      })
    )

    const messages = flushed
      .logs()
      .map((l) => ({ message: l.message, extras: l.extras }))

    expect(messages).toMatchInlineSnapshot(`
      Array [
        Object {
          "extras": undefined,
          "message": "Dispatching",
        },
        Object {
          "extras": Object {
            "plugin": "Amplitude",
          },
          "message": "plugin",
        },
        Object {
          "extras": Object {
            "plugin": "FullStory",
          },
          "message": "plugin",
        },
        Object {
          "extras": Object {
            "error": [Error: Boom!],
            "plugin": "Amplitude",
          },
          "message": "plugin Error",
        },
        Object {
          "extras": Object {
            "type": "track",
          },
          "message": "Delivered",
        },
      ]
    `)
  })

  test('attempts `after` plugins', async () => {
    const eq = new EventQueue()

    const afterFailed: Plugin = {
      ...testPlugin,
      name: 'after-failed',
      type: 'after',
      track: async () => {
        throw new Error('Boom!')
      },
    }

    const after: Plugin = {
      ...testPlugin,
      name: 'after',
      type: 'after',
    }

    await eq.register(Context.system(), afterFailed, ajs)
    await eq.register(Context.system(), after, ajs)

    const flushed = await eq.dispatch(
      new Context({
        type: 'track',
      })
    )

    const messages = flushed
      .logs()
      .map((l) => ({ message: l.message, extras: l.extras }))
    expect(messages).toMatchInlineSnapshot(`
      Array [
        Object {
          "extras": undefined,
          "message": "Dispatching",
        },
        Object {
          "extras": Object {
            "plugin": "after-failed",
          },
          "message": "plugin",
        },
        Object {
          "extras": Object {
            "plugin": "after",
          },
          "message": "plugin",
        },
        Object {
          "extras": Object {
            "error": [Error: Boom!],
            "plugin": "after-failed",
          },
          "message": "plugin Error",
        },
        Object {
          "extras": Object {
            "type": "track",
          },
          "message": "Delivered",
        },
      ]
    `)
  })

  test('runs `enrichment` and `before` inline', async () => {
    const eq = new EventQueue()

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        name: 'Kiwi',
        type: 'enrichment',
        track: async (ctx) => {
          ctx.updateEvent('properties.kiwi', '🥝')
          return ctx
        },
      },
      ajs
    )

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        name: 'Watermelon',
        type: 'enrichment',
        track: async (ctx) => {
          ctx.updateEvent('properties.watermelon', '🍉')
          return ctx
        },
      },
      ajs
    )

    await eq.register(
      Context.system(),
      {
        ...testPlugin,
        name: 'Before',
        type: 'before',
        track: async (ctx) => {
          ctx.stats.increment('before')
          return ctx
        },
      },
      ajs
    )

    const flushed = await eq.dispatch(
      new Context({
        type: 'track',
      })
    )

    expect(flushed.event.properties).toEqual({
      watermelon: '🍉',
      kiwi: '🥝',
    })

    expect(flushed.stats.metrics.map((m) => m.metric)).toContain('before')
  })

  test('respects execution order', async () => {
    const eq = new EventQueue()

    let trace = 0

    const before: Plugin = {
      ...testPlugin,
      name: 'Before',
      type: 'before',
      track: async (ctx) => {
        trace++
        expect(trace).toBe(1)
        return ctx
      },
    }

    const enrichment: Plugin = {
      ...testPlugin,
      name: 'Enrichment',
      type: 'enrichment',
      track: async (ctx) => {
        trace++
        expect(trace === 2 || trace === 3).toBe(true)
        return ctx
      },
    }

    const enrichmentTwo: Plugin = {
      ...testPlugin,
      name: 'Enrichment 2',
      type: 'enrichment',
      track: async (ctx) => {
        trace++
        expect(trace === 2 || trace === 3).toBe(true)
        return ctx
      },
    }

    const destination: Plugin = {
      ...testPlugin,
      name: 'Destination',
      type: 'destination',
      track: async (ctx) => {
        trace++
        expect(trace).toBe(4)
        return ctx
      },
    }

    // shuffle plugins so we can verify order
    const plugins = shuffle([before, enrichment, enrichmentTwo, destination])
    for (const xt of plugins) {
      await eq.register(Context.system(), xt, ajs)
    }

    await eq.dispatch(
      new Context({
        type: 'track',
      })
    )

    expect(trace).toBe(4)
  })
})
