import { Context } from '@/core/context'
import { Plugin } from '@/core/plugin'
import { JSDOM } from 'jsdom'
import { Analytics } from '../analytics'
import { Group } from '../core/user'
import { LegacyDestination } from '../plugins/ajs-destination'
import { PersistedPriorityQueue } from '../lib/priority-queue/persisted'
// @ts-ignore loadLegacySettings mocked dependency is accused as unused
import { AnalyticsBrowser, loadLegacySettings } from '../browser'
// @ts-ignore isOffline mocked dependency is accused as unused
import { isOffline } from '../core/connection'
import * as SegmentPlugin from '../plugins/segmentio'
import jar from 'js-cookie'
import { AMPLITUDE_WRITEKEY, TEST_WRITEKEY } from './test-writekeys'

const sleep = (time: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, time)
  })

const xt: Plugin = {
  name: 'Test Plugin',
  type: 'utility',
  version: '1.0',

  load(_ctx: Context): Promise<void> {
    return Promise.resolve()
  },

  isLoaded(): boolean {
    return true
  },

  track: async (ctx) => ctx,
  identify: async (ctx) => ctx,
  page: async (ctx) => ctx,
  group: async (ctx) => ctx,
  alias: async (ctx) => ctx,
}

const amplitude: Plugin = {
  ...xt,
  name: 'Amplitude',
  type: 'destination',
}

const googleAnalytics: Plugin = {
  ...xt,
  name: 'Google Analytics',
  type: 'destination',
}

const enrichBilling: Plugin = {
  ...xt,
  name: 'Billing Enrichment',
  type: 'enrichment',

  track: async (ctx) => {
    ctx.event.properties = {
      ...ctx.event.properties,
      billingPlan: 'free-99',
    }
    return ctx
  },
}

const writeKey = TEST_WRITEKEY

describe('Initialization', () => {
  beforeEach(async () => {
    jest.resetAllMocks()
  })

  it('loads plugins', async () => {
    await AnalyticsBrowser.load({
      writeKey,
      plugins: [xt],
    })

    expect(xt.isLoaded()).toBe(true)
  })

  it('loads async plugins', async () => {
    let pluginLoaded = false
    const onLoad = jest.fn(() => {
      pluginLoaded = true
    })

    const lazyPlugin: Plugin = {
      name: 'Test 2',
      type: 'utility',
      version: '1.0',

      load: async (_ctx) => {
        setTimeout(onLoad, 300)
      },
      isLoaded: () => {
        return pluginLoaded
      },
    }

    jest.spyOn(lazyPlugin, 'load')
    await AnalyticsBrowser.load({ writeKey, plugins: [lazyPlugin] })

    expect(lazyPlugin.load).toHaveBeenCalled()
    expect(onLoad).not.toHaveBeenCalled()
    expect(pluginLoaded).toBe(false)

    await sleep(300)

    expect(onLoad).toHaveBeenCalled()
    expect(pluginLoaded).toBe(true)
  })

  it('ready method is called only when all plugins with ready have declared themselves as ready', async () => {
    const ready = jest.fn()

    const lazyPlugin1: Plugin = {
      name: 'Test 2',
      type: 'destination',
      version: '1.0',

      load: async (_ctx) => {},
      ready: async () => {
        return new Promise((resolve) => setTimeout(resolve, 300))
      },
      isLoaded: () => true,
    }

    const lazyPlugin2: Plugin = {
      name: 'Test 2',
      type: 'destination',
      version: '1.0',

      load: async (_ctx) => {},
      ready: async () => {
        return new Promise((resolve) => setTimeout(resolve, 100))
      },
      isLoaded: () => true,
    }

    jest.spyOn(lazyPlugin1, 'load')
    jest.spyOn(lazyPlugin2, 'load')
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [lazyPlugin1, lazyPlugin2, xt],
    })

    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    analytics.ready(ready)
    expect(lazyPlugin1.load).toHaveBeenCalled()
    expect(lazyPlugin2.load).toHaveBeenCalled()
    expect(ready).not.toHaveBeenCalled()

    await sleep(100)
    expect(ready).not.toHaveBeenCalled()

    await sleep(200)
    expect(ready).toHaveBeenCalled()
  })

  it('calls page if initialpageview is set', async () => {
    jest.mock('../analytics')
    const mockPage = jest.fn().mockImplementation(() => Promise.resolve())
    Analytics.prototype.page = mockPage

    await AnalyticsBrowser.load({ writeKey }, { initialPageview: true })

    expect(mockPage).toHaveBeenCalled()
  })

  it('does not call page if initialpageview is not set', async () => {
    jest.mock('../analytics')
    const mockPage = jest.fn()
    Analytics.prototype.page = mockPage
    await AnalyticsBrowser.load({ writeKey }, { initialPageview: false })
    expect(mockPage).not.toHaveBeenCalled()
  })

  describe('options.integrations permutations', () => {
    const settings = { writeKey }

    it('does not load Segment.io if integrations.All is false and Segment.io is not listed', async () => {
      const options: { integrations: { [key: string]: boolean } } = {
        integrations: { All: false },
      }
      const analyticsResponse = await AnalyticsBrowser.load(settings, options)

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(segmentio).toBeUndefined()
    })

    it('does not load Segment.io if its set to false', async () => {
      const options: { integrations?: { [key: string]: boolean } } = {
        integrations: { 'Segment.io': false },
      }
      const analyticsResponse = await AnalyticsBrowser.load(settings, options)

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(segmentio).toBeUndefined()
    })

    it('loads Segment.io if integrations.All is false and Segment.io is listed', async () => {
      const options: { integrations: { [key: string]: boolean } } = {
        integrations: { All: false, 'Segment.io': true },
      }
      const analyticsResponse = await AnalyticsBrowser.load(settings, options)

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(segmentio).toBeDefined()
    })

    it('loads Segment.io if integrations.All is undefined', async () => {
      const options: { integrations: { [key: string]: boolean } } = {
        integrations: { 'Segment.io': true },
      }
      const analyticsResponse = await AnalyticsBrowser.load(settings, options)

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(segmentio).toBeDefined()
    })

    it('loads Segment.io if integrations is undefined', async () => {
      const options: { integrations?: { [key: string]: boolean } } = {
        integrations: undefined,
      }
      const analyticsResponse = await AnalyticsBrowser.load(settings, options)

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(segmentio).toBeDefined()
    })

    it('loads selected plugins when Segment.io is false', async () => {
      const options: { integrations?: { [key: string]: boolean } } = {
        integrations: {
          'Test Plugin': true,
          'Segment.io': false,
        },
      }
      const analyticsResponse = await AnalyticsBrowser.load(
        { ...settings, plugins: [xt] },
        options
      )

      const plugin = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Test Plugin'
      )

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(plugin).toBeDefined()
      expect(segmentio).toBeUndefined()
    })

    it('loads selected plugins when Segment.io and All are false', async () => {
      const options: { integrations?: { [key: string]: boolean } } = {
        integrations: {
          All: false,
          'Test Plugin': true,
          'Segment.io': false,
        },
      }
      const analyticsResponse = await AnalyticsBrowser.load(
        { ...settings, plugins: [xt] },
        options
      )

      const plugin = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Test Plugin'
      )

      const segmentio = analyticsResponse[0].queue.plugins.find(
        (p) => p.name === 'Segment.io'
      )

      expect(plugin).toBeDefined()
      expect(segmentio).toBeUndefined()
    })
  })
})

describe('Dispatch', () => {
  it('dispatches events to destinations', async () => {
    const [ajs] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude, googleAnalytics],
    })

    const ampSpy = jest.spyOn(amplitude, 'track')
    const gaSpy = jest.spyOn(googleAnalytics, 'track')

    const boo = await ajs.track('Boo!', {
      total: 25,
      userId: '👻',
    })

    expect(ampSpy).toHaveBeenCalledWith(boo)
    expect(gaSpy).toHaveBeenCalledWith(boo)
  })

  it('does not dispatch events to destinations on deny list', async () => {
    const [ajs] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude, googleAnalytics],
    })

    const ampSpy = jest.spyOn(amplitude, 'track')
    const gaSpy = jest.spyOn(googleAnalytics, 'track')

    const boo = await ajs.track(
      'Boo!',
      {
        total: 25,
        userId: '👻',
      },
      {
        integrations: {
          Amplitude: false,
        },
      }
    )

    expect(gaSpy).toHaveBeenCalledWith(boo)
    expect(ampSpy).not.toHaveBeenCalled()
  })

  it('enriches events before dispatching', async () => {
    const [ajs] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [enrichBilling, amplitude, googleAnalytics],
    })

    const boo = await ajs.track('Boo!', {
      total: 25,
    })

    expect(boo.event.properties).toMatchInlineSnapshot(`
      Object {
        "billingPlan": "free-99",
        "total": 25,
      }
    `)
  })

  it('collects metrics for every event', async () => {
    const [ajs] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude],
    })

    const delivered = await ajs.track('Fruit Basket', {
      items: ['🍌', '🍇', '🍎'],
      userId: 'Healthy person',
    })

    const metrics = delivered.stats.metrics

    expect(metrics.map((m) => m.metric)).toMatchInlineSnapshot(`
      Array [
        "message_dispatched",
        "plugin_time",
        "plugin_time",
        "plugin_time",
        "message_delivered",
        "plugin_time",
        "delivered",
      ]
    `)
  })
})

describe('Group', () => {
  it('manages Group state', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })

    const group = analytics.group() as Group

    const ctx = (await analytics.group('coolKids', {
      coolKids: true,
    })) as Context

    expect(ctx.event.groupId).toEqual('coolKids')
    expect(ctx.event.traits).toEqual({ coolKids: true })

    expect(group.id()).toEqual('coolKids')
    expect(group.traits()).toEqual({ coolKids: true })
  })
})

describe('Alias', () => {
  it('generates alias events', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude],
    })

    jest.spyOn(amplitude, 'alias')

    const ctx = await analytics.alias('netto farah', 'netto')

    expect(ctx.event.userId).toEqual('netto farah')
    expect(ctx.event.previousId).toEqual('netto')

    expect(amplitude.alias).toHaveBeenCalled()
  })

  it('falls back to userID in cookies if no id passed', async () => {
    jar.set('ajs_user_id', 'dan')
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude],
    })

    jest.spyOn(amplitude, 'alias')

    // @ts-ignore ajs 1.0 parity - allows empty alias calls
    const ctx = await analytics.alias()

    expect(ctx.event.userId).toEqual('dan')
    expect(amplitude.alias).toHaveBeenCalled()
  })
})

describe('pageview', () => {
  it('makes a page call with the given url', async () => {
    console.warn = (): void => {}
    const analytics = new Analytics({ writeKey: writeKey })
    const mockPage = jest.spyOn(analytics, 'page')
    await analytics.pageview('www.foo.com')

    expect(mockPage).toHaveBeenCalledWith({ path: 'www.foo.com' })
  })
})

describe('setAnonymousId', () => {
  it('calling setAnonymousId will set a new anonymousId and returns it', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude],
    })

    const currentAnonymousId = analytics.user().anonymousId()
    expect(currentAnonymousId).toBeDefined()
    expect(currentAnonymousId).toHaveLength(36)

    const newAnonymousId = analytics.setAnonymousId('🦹‍♀️')

    expect(analytics.user().anonymousId()).toEqual('🦹‍♀️')
    expect(newAnonymousId).toEqual('🦹‍♀️')
  })
})

describe('addSourceMiddleware', () => {
  it('supports registering source middlewares', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })

    await analytics
      .addSourceMiddleware(({ next, payload }) => {
        payload.obj.context = {
          hello: 'from the other side',
        }
        next(payload)
      })
      .catch((err) => {
        throw err
      })

    const ctx = await analytics.track('Hello!')

    expect(ctx.event.context).toMatchObject({
      hello: 'from the other side',
    })
  })
})

describe('addDestinationMiddleware', () => {
  beforeEach(async () => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    const html = `
    <!DOCTYPE html>
      <head>
        <script>'hi'</script>
      </head>
      <body>
      </body>
    </html>
    `.trim()

    const jsd = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('supports registering destination middlewares', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })

    const amplitude = new LegacyDestination(
      'amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      {}
    )

    await analytics.register(amplitude)
    await amplitude.ready()

    analytics
      .addDestinationMiddleware('amplitude', ({ next, payload }) => {
        payload.obj.properties!.hello = 'from the other side'
        next(payload)
      })
      .catch((err) => {
        throw err
      })

    const integrationMock = jest.spyOn(amplitude.integration!, 'track')
    const ctx = await analytics.track('Hello!')

    // does not modify the event
    expect(ctx.event.properties).not.toEqual({
      hello: 'from the other side',
    })

    const calledWith = integrationMock.mock.calls[0][0].properties()

    // only impacted this destination
    expect(calledWith).toEqual({
      ...ctx.event.properties,
      hello: 'from the other side',
    })
  })
})

describe('use', () => {
  it('registers a legacyPlugin', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })

    const legacyPlugin = jest.fn()
    analytics.use(legacyPlugin)

    expect(legacyPlugin).toHaveBeenCalledWith(analytics)
  })
})

describe('timeout', () => {
  it('has a default timeout value', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })
    //@ts-ignore
    expect(analytics.settings.timeout).toEqual(300)
  })

  it('can set a timeout value', async () => {
    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
    })
    analytics.timeout(50)
    //@ts-ignore
    expect(analytics.settings.timeout).toEqual(50)
  })
})

describe('deregister', () => {
  beforeEach(async () => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    const html = `
    <!DOCTYPE html>
      <head>
        <script>'hi'</script>
      </head>
      <body>
      </body>
    </html>
    `.trim()

    const jsd = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('deregisters a plugin given its name', async () => {
    const unload = jest.fn(
      (): Promise<unknown> => {
        return Promise.resolve()
      }
    )
    xt.unload = unload

    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [xt],
    })

    await analytics.deregister('Test Plugin')
    expect(xt.unload).toHaveBeenCalled()
  })

  it('cleans up the DOM when deregistering a legacy integration', async () => {
    const amplitude = new LegacyDestination(
      'amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      {}
    )

    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude],
    })

    await analytics.ready()

    const scriptsLength = window.document.scripts.length
    expect(scriptsLength).toBeGreaterThan(1)

    await analytics.deregister('amplitude')
    expect(window.document.scripts.length).toBe(scriptsLength - 1)
  })
})

describe('retries', () => {
  const testPlugin: Plugin = {
    name: 'test',
    type: 'before',
    version: '0.1.0',
    load: () => Promise.resolve(),
    isLoaded: () => true,
  }

  const fruitBasketEvent = new Context({
    type: 'track',
    event: 'Fruit Basket',
  })

  beforeEach(async () => {
    // @ts-ignore ignore reassining function
    loadLegacySettings = jest.fn().mockReturnValue(
      Promise.resolve({
        integrations: { 'Segment.io': { retryQueue: false } },
      })
    )
  })

  it('does not retry errored events if retryQueue setting is set to false', async () => {
    const [ajs] = await AnalyticsBrowser.load(
      { writeKey: TEST_WRITEKEY },
      { retryQueue: false }
    )

    expect(ajs.queue.queue).toStrictEqual(
      new PersistedPriorityQueue(1, 'event-queue')
    )

    await ajs.queue.register(
      Context.system(),
      {
        ...testPlugin,
        track: (_ctx) => {
          throw new Error('aaay')
        },
      },
      ajs
    )

    // Dispatching an event will push it into the priority queue.
    await ajs.queue.dispatch(fruitBasketEvent).catch(() => {})

    // we make sure the queue is flushed and there are no events queued up.
    expect(ajs.queue.queue.length).toBe(0)
    const flushed = await ajs.queue.flush()
    expect(flushed).toStrictEqual([])

    // as maxAttempts === 1, only one attempt was made.
    // getAttempts(fruitBasketEvent) === 2 means the event's attemp was incremented,
    // but the condition "(getAttempts(event) > maxAttempts) { return false }"
    // aborted the retry
    expect(ajs.queue.queue.getAttempts(fruitBasketEvent)).toEqual(2)
  })

  it('does not queue up events when offline if retryQueue setting is set to false', async () => {
    const [ajs] = await AnalyticsBrowser.load({ writeKey })

    await ajs.queue.register(
      Context.system(),
      {
        ...testPlugin,
        ready: () => Promise.resolve(true),
        track: (ctx) => ctx,
      },
      ajs
    )

    // @ts-ignore ignore reassining function
    isOffline = jest.fn().mockReturnValue(true)

    // eslint-disable-next-line @typescript-eslint/no-floating-promises
    ajs.track('event')

    expect(ajs.queue.queue.length).toBe(0)
  })
})

describe('Segment.io overrides', () => {
  it('allows for overriding Segment.io settings', async () => {
    jest.spyOn(SegmentPlugin, 'segmentio')

    await AnalyticsBrowser.load(
      { writeKey },
      {
        integrations: {
          'Segment.io': {
            apiHost: 'https://my.endpoint.com',
            anotherSettings: '👻',
          },
        },
      }
    )

    expect(SegmentPlugin.segmentio).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        apiHost: 'https://my.endpoint.com',
        anotherSettings: '👻',
      }),
      expect.anything()
    )
  })
})

describe('.Integrations', () => {
  beforeEach(async () => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    const html = `
    <!DOCTYPE html>
      <head>
        <script>'hi'</script>
      </head>
      <body>
      </body>
    </html>
    `.trim()

    const jsd = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('lists all legacy destinations', async () => {
    const amplitude = new LegacyDestination(
      'Amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      {}
    )

    const ga = new LegacyDestination('Google-Analytics', 'latest', {}, {})

    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude, ga],
    })

    await analytics.ready()

    expect(analytics.Integrations).toMatchInlineSnapshot(`
      Object {
        "Amplitude": [Function],
        "Google-Analytics": [Function],
      }
    `)
  })

  it('catches destinations with dots in their names', async () => {
    const amplitude = new LegacyDestination(
      'Amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      {}
    )

    const ga = new LegacyDestination('Google-Analytics', 'latest', {}, {})
    const customerIO = new LegacyDestination('Customer.io', 'latest', {}, {})

    const [analytics] = await AnalyticsBrowser.load({
      writeKey,
      plugins: [amplitude, ga, customerIO],
    })

    await analytics.ready()

    expect(analytics.Integrations).toMatchInlineSnapshot(`
      Object {
        "Amplitude": [Function],
        "Customer.io": [Function],
        "Google-Analytics": [Function],
      }
    `)
  })
})
