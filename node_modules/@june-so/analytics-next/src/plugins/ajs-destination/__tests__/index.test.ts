/* eslint-disable @typescript-eslint/no-floating-promises */
import jsdom from 'jsdom'
import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { ajsDestinations, LegacyDestination } from '..'
import { Analytics } from '../../../analytics'
import { LegacySettings } from '../../../browser'
import { Context } from '../../../core/context'
import { Plan } from '../../../core/events'
import { tsubMiddleware } from '../../routing-middleware'
import { AMPLITUDE_WRITEKEY } from '../../../__tests__/test-writekeys'

const cdnResponse: LegacySettings = {
  integrations: {
    Zapier: {
      type: 'server',
    },
    WithNoVersion: {
      type: 'browser',
    },
    WithProperTypeComponent: {
      versionSettings: {
        componentTypes: ['browser'],
      },
    },
    WithVersionSettings: {
      versionSettings: {
        version: '1.2.3',
      },
      type: 'browser',
    },
    WithVersionOverrides: {
      versionSettings: {
        version: '1.2.3',
        override: '9.9.9',
      },
      type: 'browser',
    },
    'Amazon S3': {},
    Amplitude: {
      type: 'browser',
    },
    Segmentio: {
      type: 'browser',
    },
    Iterable: {
      type: 'browser',
      name: 'Iterable',
    },
  },
  middlewareSettings: {
    routingRules: [
      {
        matchers: [
          {
            ir: '["=","event",{"value":"Item Impression"}]',
            type: 'fql',
          },
        ],
        scope: 'destinations',
        // eslint-disable-next-line @typescript-eslint/camelcase
        target_type: 'workspace::project::destination',
        transformers: [[{ type: 'drop' }]],
        destinationName: 'Amplitude',
      },
    ],
  },
}

const fetchSettings = Promise.resolve({
  json: () => Promise.resolve(cdnResponse),
})

jest.mock('unfetch', () => {
  return jest.fn()
})

describe('loading ajsDestinations', () => {
  beforeEach(async () => {
    jest.resetAllMocks()

    // @ts-ignore: ignore Response required fields
    mocked(unfetch).mockImplementation((): Promise<Response> => fetchSettings)
  })

  it('loads version overrides', async () => {
    const destinations = await ajsDestinations(cdnResponse, {}, {})

    const withVersionSettings = destinations.find(
      (d) => d.name === 'WithVersionSettings'
    )

    const withVersionOverrides = destinations.find(
      (d) => d.name === 'WithVersionOverrides'
    )

    const withNoVersion = destinations.find((d) => d.name === 'WithNoVersion')

    expect(withVersionSettings?.version).toBe('1.2.3')
    expect(withVersionOverrides?.version).toBe('9.9.9')
    expect(withNoVersion?.version).toBe('latest')
  })

  // This test should temporary. It must be deleted once we fix the Iterable metadata
  it('ignores Iterable', async () => {
    const destinations = await ajsDestinations(cdnResponse, {}, {})
    const iterable = destinations.find((d) => d.name === 'Iterable')
    expect(iterable).toBeUndefined()
  })

  describe('versionSettings.components', () => {
    it('ignores [componentType:browser] when bundlingStatus is unbundled', async () => {
      const destinations = await ajsDestinations(
        {
          integrations: {
            'Some server destination': {
              versionSettings: {
                componentTypes: ['server'],
              },
              bundlingStatus: 'bundled', // this combination will never happen
            },
            'Device Mode Customer.io': {
              versionSettings: {
                componentTypes: ['browser'],
              },
              bundlingStatus: 'bundled',
            },
            'Cloud Mode Customer.io': {
              versionSettings: {
                componentTypes: ['browser'],
              },
              bundlingStatus: 'unbundled',
            },
          },
        },
        {},
        {}
      )
      expect(destinations.length).toBe(1)
    })

    it('loads [componentType:browser] when bundlingStatus is not defined', async () => {
      const destinations = await ajsDestinations(
        {
          integrations: {
            'Some server destination': {
              versionSettings: {
                componentTypes: ['server'],
              },
              bundlingStatus: 'bundled', // this combination will never happen
            },
            'Device Mode Customer.io': {
              versionSettings: {
                componentTypes: ['browser'],
              },
              bundlingStatus: 'bundled',
            },
            'Device Mode no bundling status Customer.io': {
              versionSettings: {
                componentTypes: ['browser'],
              },
            },
          },
        },
        {},
        {}
      )
      expect(destinations.length).toBe(2)
    })
  })

  it('loads type:browser legacy ajs destinations from cdn', async () => {
    const destinations = await ajsDestinations(cdnResponse, {}, {})
    // ignores segment.io
    expect(destinations.length).toBe(5)
  })

  it('ignores type:browser when bundlingStatus is unbundled', async () => {
    const destinations = await ajsDestinations(
      {
        integrations: {
          'Some server destination': {
            type: 'server',
            bundlingStatus: 'bundled', // this combination will never happen
          },
          'Device Mode Customer.io': {
            type: 'browser',
            bundlingStatus: 'bundled',
          },
          'Cloud Mode Customer.io': {
            type: 'browser',
            bundlingStatus: 'unbundled',
          },
        },
      },
      {},
      {}
    )
    expect(destinations.length).toBe(1)
  })

  it('loads type:browser when bundlingStatus is not defined', async () => {
    const destinations = await ajsDestinations(
      {
        integrations: {
          'Some server destination': {
            type: 'server',
            bundlingStatus: 'bundled', // this combination will never happen
          },
          'Device Mode Customer.io': {
            type: 'browser',
            bundlingStatus: 'bundled',
          },
          'Device Mode no bundling status Customer.io': {
            type: 'browser',
          },
        },
      },
      {},
      {}
    )
    expect(destinations.length).toBe(2)
  })

  it('ignores destinations of type:server', async () => {
    const destinations = await ajsDestinations(cdnResponse, {}, {})
    expect(destinations.find((d) => d.name === 'Zapier')).toBe(undefined)
  })

  it('does not load integrations when All:false', async () => {
    const destinations = await ajsDestinations(
      cdnResponse,
      {
        All: false,
      },
      {}
    )
    expect(destinations.length).toBe(0)
  })

  it('loads integrations when All:false, <integration>: true', async () => {
    const destinations = await ajsDestinations(
      cdnResponse,
      {
        All: false,
        Amplitude: true,
        Segmentio: false,
      },
      {}
    )
    expect(destinations.length).toBe(1)
    expect(destinations[0].name).toEqual('Amplitude')
  })

  it('adds a tsub middleware for matching rules', async () => {
    const destinations = await ajsDestinations(cdnResponse)
    const amplitude = destinations.find((d) => d.name === 'Amplitude')
    expect(amplitude?.middleware.length).toBe(1)
  })
})

describe('settings', () => {
  it('does not delete type=any', () => {
    const dest = new LegacyDestination(
      'Yandex',
      'latest',
      {
        type: 'custom',
      },
      {}
    )
    expect(dest.settings['type']).toEqual('custom')
  })

  it('deletes type=browser', () => {
    const dest = new LegacyDestination(
      'Amplitude',
      'latest',
      {
        type: 'browser',
      },
      {}
    )

    expect(dest.settings['type']).toBeUndefined()
  })
})

describe('remote loading', () => {
  const loadAmplitude = async (): Promise<LegacyDestination> => {
    const ajs = new Analytics({
      writeKey: 'abc',
    })

    const dest = new LegacyDestination(
      'Amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      {}
    )

    await dest.load(Context.system(), ajs)
    await dest.ready()
    return dest
  }

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

    const jsd = new jsdom.JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('loads integrations from the Segment CDN', async () => {
    await loadAmplitude()

    const sources = Array.from(window.document.querySelectorAll('script'))
      .map((s) => s.src)
      .filter(Boolean)

    expect(sources).toMatchObject(
      expect.arrayContaining([
        'https://cdn.segment.com/next-integrations/integrations/amplitude/latest/amplitude.dynamic.js.gz',
        expect.stringContaining(
          'https://cdn.segment.com/next-integrations/integrations/vendor/commons'
        ),
        'https://cdn.amplitude.com/libs/amplitude-5.2.2-min.gz.js',
      ])
    )
  })

  it('forwards identify calls to integration', async () => {
    const dest = await loadAmplitude()
    jest.spyOn(dest.integration!, 'identify')

    const evt = new Context({ type: 'identify' })
    await dest.identify(evt)

    expect(dest.integration?.identify).toHaveBeenCalled()
  })

  it('forwards track calls to integration', async () => {
    const dest = await loadAmplitude()
    jest.spyOn(dest.integration!, 'track')

    await dest.track(new Context({ type: 'track' }))
    expect(dest.integration?.track).toHaveBeenCalled()
  })

  it('forwards page calls to integration', async () => {
    const dest = await loadAmplitude()
    jest.spyOn(dest.integration!, 'page')

    await dest.page(new Context({ type: 'page' }))
    expect(dest.integration?.page).toHaveBeenCalled()
  })

  it('applies remote routing rules', async () => {
    const dest = await loadAmplitude()
    jest.spyOn(dest.integration!, 'track')

    dest.addMiddleware(
      tsubMiddleware(cdnResponse.middlewareSettings?.routingRules ?? [])
    )

    // this routing rule should drop the event
    await dest.track(new Context({ type: 'track', event: 'Item Impression' }))
    expect(dest.integration?.track).not.toHaveBeenCalled()
  })
})

describe('plan', () => {
  beforeEach(async () => {
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

    const jsd = new jsdom.JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  const loadAmplitude = async (plan: Plan): Promise<LegacyDestination> => {
    const ajs = new Analytics({
      writeKey: 'abc',
    })

    const dest = new LegacyDestination(
      'amplitude',
      'latest',
      {
        apiKey: AMPLITUDE_WRITEKEY,
      },
      { plan }
    )

    await dest.load(Context.system(), ajs)
    await dest.ready()
    return dest
  }

  it('does not drop events when no plan is defined', async () => {
    const dest = await loadAmplitude({})

    jest.spyOn(dest.integration!, 'track')

    await dest.track(new Context({ type: 'page', event: 'Track Event' }))
    expect(dest.integration?.track).toHaveBeenCalled()
  })

  it('drops event when event is disabled', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: false,
          integrations: { amplitude: false },
        },
      },
    })

    jest.spyOn(dest.integration!, 'track')

    const ctx = new Context({ type: 'page', event: 'Track Event' })
    await expect(() => dest.track(ctx)).rejects.toMatchInlineSnapshot(`
      ContextCancelation {
        "reason": "Event Track Event disabled for integration amplitude in tracking plan",
        "retry": false,
        "type": "Dropped by plan",
      }
    `)

    expect(dest.integration?.track).not.toHaveBeenCalled()
    expect(ctx.event.integrations).toMatchInlineSnapshot(`
      Object {
        "All": false,
        "Segment.io": true,
      }
    `)
  })

  it('does not drop events with different names', async () => {
    const dest = await loadAmplitude({
      track: {
        'Fake Track Event': {
          enabled: true,
          integrations: { amplitude: false },
        },
      },
    })

    jest.spyOn(dest.integration!, 'track')

    await dest.track(new Context({ type: 'page', event: 'Track Event' }))
    expect(dest.integration?.track).toHaveBeenCalled()
  })

  it('drops enabled event for matching destination', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { amplitude: false },
        },
      },
    })

    jest.spyOn(dest.integration!, 'track')
    const ctx = new Context({ type: 'page', event: 'Track Event' })
    await expect(() => dest.track(ctx)).rejects.toMatchInlineSnapshot(`
      ContextCancelation {
        "reason": "Event Track Event disabled for integration amplitude in tracking plan",
        "retry": false,
        "type": "Dropped by plan",
      }
    `)

    expect(dest.integration?.track).not.toHaveBeenCalled()
  })

  it('does not drop enabled event for non-matching destination', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { 'not amplitude': false },
        },
      },
    })

    jest.spyOn(dest.integration!, 'track')

    await dest.track(new Context({ type: 'page', event: 'Track Event' }))
    expect(dest.integration?.track).toHaveBeenCalled()
  })

  it('does not drop enabled event with enabled destination', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { amplitude: true },
        },
      },
    })

    jest.spyOn(dest.integration!, 'track')

    await dest.track(new Context({ type: 'page', event: 'Track Event' }))
    expect(dest.integration?.track).toHaveBeenCalled()
  })

  it('properly sets event integrations object with enabled plan', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { amplitude: true },
        },
      },
    })

    const ctx = await dest.track(
      new Context({ type: 'page', event: 'Track Event' })
    )
    expect(ctx.event.integrations).toEqual({ amplitude: true })
  })

  it('sets event integrations object when integration is disabled', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { amplitude: false },
        },
      },
    })
    jest.spyOn(dest.integration!, 'track')
    const ctx = new Context({ type: 'page', event: 'Track Event' })

    await expect(() => dest.track(ctx)).rejects.toMatchInlineSnapshot(`
      ContextCancelation {
        "reason": "Event Track Event disabled for integration amplitude in tracking plan",
        "retry": false,
        "type": "Dropped by plan",
      }
    `)

    expect(dest.integration?.track).not.toHaveBeenCalled()
    expect(ctx.event.integrations).toEqual({ amplitude: false })
  })

  it('doesnt set event integrations object with different event', async () => {
    const dest = await loadAmplitude({
      track: {
        'Track Event': {
          enabled: true,
          integrations: { amplitude: true },
        },
      },
    })

    const ctx = await dest.track(
      new Context({ type: 'page', event: 'Not Track Event' })
    )
    expect(ctx.event.integrations).toEqual({})
  })
})

describe('option overrides', () => {
  beforeEach(async () => {
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

    const jsd = new jsdom.JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('accepts settings overrides from options', async () => {
    const cdnSettings = {
      integrations: {
        Amplitude: {
          type: 'browser',
          apiKey: '123',
          secondOption: '👻',
        },
      },
    }

    const initOptions = {
      integrations: {
        Amplitude: {
          apiKey: 'abc',
          thirdOption: '🤠',
        },
      },
    }

    const destinations = await ajsDestinations(cdnSettings, {}, initOptions)
    const amplitude = destinations[0]

    await amplitude.load(Context.system(), {} as Analytics)
    await amplitude.ready()

    expect(amplitude.settings).toMatchObject({
      apiKey: 'abc', // overriden
      secondOption: '👻', // merged from cdn settings
      thirdOption: '🤠', // merged from init options
    })

    expect(amplitude.integration?.options).toEqual(
      expect.objectContaining({
        apiKey: 'abc', // overriden
        secondOption: '👻', // merged from cdn settings
        thirdOption: '🤠', // merged from init options
      })
    )
  })
})
