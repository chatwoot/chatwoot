import assert from 'assert'
import cookie from 'js-cookie'
import { SegmentioSettings } from '..'
import { normalize } from '../normalize'
import { Analytics } from '../../../analytics'
import { SegmentEvent } from '../../../core/events'
import { JSDOM } from 'jsdom'
import { version } from '../../../generated/version'

describe('before loading', () => {
  let jsdom: JSDOM

  beforeEach(async () => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    const html = `
    <!DOCTYPE html>
      <head></head>
      <body></body>
    </html>
    `.trim()

    jsdom = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsdom.window as unknown) as Window & typeof globalThis
    )
  })

  let options: SegmentioSettings
  let analytics: Analytics

  beforeEach(() => {
    options = { apiKey: 'foo' }
    analytics = new Analytics({ writeKey: options.apiKey })

    window.localStorage.clear()
  })

  afterEach(() => {
    analytics.reset()
    Object.keys(cookie.get()).map((k) => cookie.remove(k))

    if (window.localStorage) {
      window.localStorage.clear()
    }
  })
  describe('#normalize', () => {
    let object: SegmentEvent

    beforeEach(() => {
      cookie.remove('s:context.referrer')
      object = {
        type: 'track',
      }
    })

    it('should add .anonymousId', () => {
      analytics.user().anonymousId('anon-id')
      normalize(analytics, object, options, {})
      assert(object.anonymousId === 'anon-id')
    })

    it('should add .sentAt', () => {
      normalize(analytics, object, options, {})
      assert(object.sentAt)
      // assert(type(object.sentAt) === 'date')
    })

    it('should add .userId', () => {
      analytics.user().id('user-id')
      normalize(analytics, object, options, {})
      assert(object.userId === 'user-id')
    })

    it('should not replace the .userId', () => {
      analytics.user().id('user-id')
      object.userId = 'existing-id'
      normalize(analytics, object, options, {})
      assert(object.userId === 'existing-id')
    })

    it('should always add .anonymousId even if .userId is given', () => {
      const object: SegmentEvent = { userId: 'baz', type: 'track' }
      normalize(analytics, object, options, {})
      assert(object.anonymousId?.length === 36)
    })

    it('should accept anonymousId being set in an event', async () => {
      const object: SegmentEvent = {
        userId: 'baz',
        type: 'track',
        anonymousId: '👻',
      }
      normalize(analytics, object, options, {})
      expect(object.anonymousId).toEqual('👻')
    })

    it('should add .context', () => {
      normalize(analytics, object, options, {})
      assert(object.context)
    })

    it('should not rewrite context if provided', () => {
      const ctx = {}
      const obj = { ...object, context: ctx }
      normalize(analytics, obj, options, {})
      expect(obj.context).toEqual(ctx)
    })

    it('should copy .options to .context', () => {
      const opts = {}
      const obj = { ...object, options: opts }
      normalize(analytics, obj, options, {})
      assert(obj.context === opts)
      assert(obj.options == null)
    })

    it('should add .writeKey', () => {
      normalize(analytics, object, options, {})
      assert(object.writeKey === options.apiKey)
    })

    it('should add .library', () => {
      normalize(analytics, object, options, {})
      assert(object.context?.library)
      assert(object.context?.library.name === 'analytics.js')
      assert(object.context?.library.version === `npm:next-${version}`)
    })

    it('should allow override of .library', () => {
      const ctx = {
        library: {
          name: 'analytics-wordpress',
          version: '1.0.3',
        },
      }
      const obj = { ...object, context: ctx }

      normalize(analytics, obj, options, {})

      assert(obj.context?.library)
      assert(obj.context?.library.name === 'analytics-wordpress')
      assert(obj.context?.library.version === '1.0.3')
    })

    it('should add .userAgent', () => {
      normalize(analytics, object, options, {})
      assert(object.context?.userAgent === navigator.userAgent)
    })

    it('should add .locale', () => {
      normalize(analytics, object, options, {})
      assert(object.context?.locale === navigator.language)
    })

    it('should not replace .locale if provided', () => {
      const ctx = {
        locale: 'foobar',
      }
      const obj = { ...object, context: ctx }
      normalize(analytics, obj, options, {})
      assert(obj.context?.locale === 'foobar')
    })

    it('should add .campaign', () => {
      jsdom.reconfigure({
        url:
          'http://localhost?utm_source=source&utm_medium=medium&utm_term=term&utm_content=content&utm_campaign=name',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert(object.context.campaign)
      assert(object.context.campaign.source === 'source')
      assert(object.context.campaign.medium === 'medium')
      assert(object.context.campaign.term === 'term')
      assert(object.context.campaign.content === 'content')
      assert(object.context.campaign.name === 'name')
    })

    it('should decode query params', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm_source=%5BFoo%5D',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert(object.context.campaign)
      assert(object.context.campaign.source === '[Foo]')
    })

    it('should guard against undefined utm params', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm_source',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert(object.context.campaign)
      assert(object.context.campaign.source === '')
    })

    it('should guard against empty utm params', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm_source=',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert(object.context.campaign)
      assert(object.context.campaign.source === '')
    })

    it('only parses utm params suffixed with _', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert.deepStrictEqual(object.context.campaign, {})
    })

    it('should guard against short utm params', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm_',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert.deepStrictEqual(object.context.campaign, {})
    })

    it('should allow override of .campaign', () => {
      jsdom.reconfigure({
        url:
          'http://localhost?utm_source=source&utm_medium=medium&utm_term=term&utm_content=content&utm_campaign=name',
      })

      const obj = {
        ...object,
        context: {
          campaign: {
            source: 'overrideSource',
            medium: 'overrideMedium',
            term: 'overrideTerm',
            content: 'overrideContent',
            name: 'overrideName',
          },
        },
      }
      normalize(analytics, obj, options, {})
      assert(obj)
      assert(obj.context)
      assert(obj.context.campaign)
      assert(obj.context.campaign.source === 'overrideSource')
      assert(obj.context.campaign.medium === 'overrideMedium')
      assert(obj.context.campaign.term === 'overrideTerm')
      assert(obj.context.campaign.content === 'overrideContent')
      assert(obj.context.campaign.name === 'overrideName')
    })

    it('should add .referrer.id and .referrer.type', () => {
      jsdom.reconfigure({
        url: 'http://localhost?utm_source=source&urid=medium',
      })

      normalize(analytics, object, options, {})
      assert(object)
      assert(object.context)
      assert(object.context.referrer)
      expect(object.context.referrer.id).toEqual('medium')
      assert(object.context.referrer.type === 'millennial-media')
    })

    it('should add .referrer.id and .referrer.type from cookie', () => {
      cookie.set('s:context.referrer', '{"id":"baz","type":"millennial-media"}')

      jsdom.reconfigure({
        url: 'http://localhost?utm_source=source',
      })

      normalize(analytics, object, options, {})

      assert(object)
      assert(object.context)
      assert(object.context.referrer)
      assert(object.context.referrer.id === 'baz')
      assert(object.context.referrer.type === 'millennial-media')
    })

    it('should add .referrer.id and .referrer.type from cookie when no query is given', () => {
      cookie.set(
        's:context.referrer',
        '{"id":"medium","type":"millennial-media"}'
      )

      jsdom.reconfigure({
        url: 'http://localhost',
      })

      normalize(analytics, object, options, {})
      assert(object)
      assert(object.context)
      assert(object.context.referrer)
      assert(object.context.referrer.id === 'medium')
      assert(object.context.referrer.type === 'millennial-media')
    })

    it('shouldnt add non amp ga cookie', () => {
      cookie.set('_ga', 'some-nonamp-id')
      normalize(analytics, object, options, {})
      assert(object)
      assert(object.context)
      assert(!object.context.amp)
    })

    it('should add .amp.id from store', () => {
      cookie.set('_ga', 'amp-foo')
      normalize(analytics, object, options, {})
      assert(object)
      assert(object.context)
      assert(object.context.amp)
      assert(object.context.amp.id === 'amp-foo')
    })

    it('should not add .amp if theres no _ga', () => {
      cookie.remove('_ga')
      normalize(analytics, object, options, {})
      assert(object)
      assert(object.context)
      assert(!object.context.amp)
    })

    describe('failed initializations', () => {
      it.skip('should add failedInitializations as part of _metadata object if this.analytics.failedInitilizations is not empty', () => {})
    })

    describe('unbundling', () => {
      it('should add a list of bundled integrations', () => {
        normalize(analytics, object, options, {
          'Segment.io': {},
          other: {
            bundlingStatus: 'bundled',
          },
        })

        assert(object)
        assert(object._metadata)
        assert.deepEqual(object._metadata.bundled, ['Segment.io', 'other'])
      })

      it('should add a list of bundled ids', () => {
        normalize(
          analytics,
          object,
          {
            ...options,
            maybeBundledConfigIds: {
              other: ['o_123', 'o_456'],
            },
          },
          {
            'Segment.io': {},
            other: {
              bundlingStatus: 'bundled',
            },
          }
        )

        assert(object)
        assert(object._metadata)
        assert.deepEqual(object._metadata.bundledIds, ['o_123', 'o_456'])
      })

      it('should add a list of unbundled integrations when `unbundledIntegrations` is set', () => {
        options.unbundledIntegrations = ['other2']
        normalize(analytics, object, options, {
          other2: {
            bundlingStatus: 'unbundled',
          },
        })

        assert(object)
        assert(object._metadata)
        assert.deepEqual(object._metadata.unbundled, ['other2'])
      })
    })

    it('should pick up messageId from AJS', () => {
      normalize(analytics, object, options, {}) // ajs core generates the message ID here
      const messageId = object.messageId

      normalize(analytics, object, options, {})
      assert.equal(object.messageId, messageId)
    })
  })
})
