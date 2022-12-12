import assert from 'assert'
import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { segmentio, SegmentioSettings } from '..'
import { Analytics } from '../../../analytics'
import { Plugin } from '../../../core/plugin'
import { pageEnrichment } from '../../page-enrichment'
import cookie from 'js-cookie'

jest.mock('unfetch', () => {
  return jest.fn()
})

describe('Segment.io', () => {
  let options: SegmentioSettings
  let analytics: Analytics
  let segment: Plugin
  let spyMock: jest.SpyInstance

  beforeEach(async () => {
    jest.resetAllMocks()
    jest.restoreAllMocks()

    options = { apiKey: 'foo' }
    analytics = new Analytics({ writeKey: options.apiKey })
    segment = segmentio(analytics, options, {})

    await analytics.register(segment, pageEnrichment)

    window.localStorage.clear()

    // @ts-ignore
    spyMock = mocked(unfetch).mockResolvedValue({
      ok: true,
    } as Response)
  })

  function resetCookies(): void {
    Object.keys(cookie.get()).map((key) => cookie.remove(key))
  }

  afterEach(async () => {
    analytics.reset()
    resetCookies()

    window.localStorage.clear()
  })

  describe('#page', () => {
    it('should enqueue section, name and properties', async () => {
      await analytics.page('section', 'name', { property: true }, { opt: true })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/page"`)

      const body = JSON.parse(params.body)

      assert(body.name === 'name')
      assert(body.category === 'section')
      assert(body.properties.property === true)
      assert(body.context.opt === true)
      assert(body.timestamp)
    })

    it('sets properties when name and category are null', async () => {
      // @ts-ignore test a valid ajsc page call
      await analytics.page(null, { foo: 'bar' })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/page"`)

      const body = JSON.parse(params.body)

      assert(body.properties.foo === 'bar')
    })
  })

  describe('#identify', () => {
    it('should enqueue an id and traits', async () => {
      await analytics.identify('id', { trait: true }, { opt: true })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/identify"`)

      const body = JSON.parse(params.body)
      assert(body.userId === 'id')
      assert(body.traits.trait === true)
      assert(body.context.opt === true)
      assert(body.timestamp)
    })

    it('should set traits with null id', async () => {
      await analytics.identify(null, { trait: true }, { opt: true })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/identify"`)

      const body = JSON.parse(params.body)
      assert(body.userId === null)
      assert(body.traits.trait === true)
      assert(!body.context.trait)
      assert(body.context.opt === true)
      assert(body.timestamp)
    })
  })

  describe('#track', () => {
    it('should enqueue an event and properties', async () => {
      await analytics.track('event', { prop: true }, { opt: true })
      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/track"`)

      const body = JSON.parse(params.body)

      assert(body.event === 'event')
      assert(body.context.opt === true)
      assert(body.properties.prop === true)
      assert(body.traits == null)
      assert(body.timestamp)
    })
  })

  describe('#group', () => {
    it('should enqueue groupId and traits', async () => {
      await analytics.group('id', { trait: true }, { opt: true })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/group"`)

      const body = JSON.parse(params.body)

      assert(body.groupId === 'id')
      assert(body.context.opt === true)
      assert(body.traits.trait === true)
      assert(body.timestamp)
    })

    it('should set traits with null id', async () => {
      await analytics.group(null, { trait: true }, { opt: true })

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/group"`)

      const body = JSON.parse(params.body)

      assert(body.groupId === null)
      assert(body.context.opt === true)
      assert(body.traits.trait === true)
      assert(!body.context.trait)
      assert(body.timestamp)
    })
  })

  describe('#alias', () => {
    it('should enqueue .userId and .previousId', async () => {
      await analytics.alias('to', 'from')
      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/alias"`)

      const body = JSON.parse(params.body)
      assert(body.previousId === 'from')
      assert(body.userId === 'to')
      assert(body.timestamp)
    })

    it('should fallback to user.anonymousId if .previousId is omitted', async () => {
      analytics.user().anonymousId('anon-id')
      await analytics.alias('to')

      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/alias"`)

      const body = JSON.parse(params.body)
      assert(body.previousId === 'anon-id')
      assert(body.userId === 'to')
      assert(body.timestamp)
    })

    it('should fallback to user.anonymousId if .previousId and user.id are falsey', async () => {
      await analytics.alias('to')
      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/alias"`)

      const body = JSON.parse(params.body)
      assert(body.previousId)
      assert(body.previousId.length === 36)
      assert(body.userId === 'to')
    })

    it('should rename `.from` and `.to` to `.previousId` and `.userId`', async () => {
      await analytics.alias('user-id', 'previous-id')
      const [url, params] = spyMock.mock.calls[0]
      expect(url).toMatchInlineSnapshot(`"https://api.june.so/sdk/alias"`)

      const body = JSON.parse(params.body)
      assert(body.previousId === 'previous-id')
      assert(body.userId === 'user-id')
      assert(body.from == null)
      assert(body.to == null)
    })
  })
})
