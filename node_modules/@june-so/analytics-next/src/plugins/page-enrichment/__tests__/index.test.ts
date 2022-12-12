import { Analytics } from '@/analytics'
import { pageEnrichment, pageDefaults } from '..'

let ajs: Analytics

describe('Page Enrichment', () => {
  beforeEach(async () => {
    ajs = new Analytics({
      writeKey: 'abc_123',
    })

    await ajs.register(pageEnrichment)
  })

  test('enriches page calls', async () => {
    const ctx = await ajs.page('Checkout', {})

    expect(ctx.event.properties).toMatchInlineSnapshot(`
      Object {
        "name": "Checkout",
        "path": "/",
        "referrer": "",
        "search": "",
        "title": "",
        "url": "http://localhost/",
      }
    `)
  })

  test('enriches track events with the page context', async () => {
    const ctx = await ajs.track('My event', {
      banana: 'phone',
    })

    expect(ctx.event.context?.page).toMatchInlineSnapshot(`
      Object {
        "path": "/",
        "referrer": "",
        "search": "",
        "title": "",
        "url": "http://localhost/",
      }
    `)
  })

  test('enriches page events with the page context', async () => {
    const ctx = await ajs.page(
      'My event',
      { banana: 'phone' },
      { page: { url: 'not-localhost' } }
    )

    expect(ctx.event.context?.page).toMatchInlineSnapshot(`
    Object {
      "path": "/",
      "referrer": "",
      "search": "",
      "title": "",
      "url": "not-localhost",
    }
  `)
  })

  test('enriches page events using properties', async () => {
    const ctx = await ajs.page('My event', { banana: 'phone', referrer: 'foo' })

    expect(ctx.event.context?.page).toMatchInlineSnapshot(`
    Object {
      "path": "/",
      "referrer": "foo",
      "search": "",
      "title": "",
      "url": "http://localhost/",
    }
  `)
  })

  test('enriches identify events with the page context', async () => {
    const ctx = await ajs.identify('Netto', {
      banana: 'phone',
    })

    expect(ctx.event.context?.page).toMatchInlineSnapshot(`
      Object {
        "path": "/",
        "referrer": "",
        "search": "",
        "title": "",
        "url": "http://localhost/",
      }
    `)
  })

  test('runs before any other plugin', async () => {
    let called = false

    await ajs.addSourceMiddleware(({ payload, next }) => {
      called = true
      expect(payload.obj?.context?.page).not.toBeFalsy()
      next(payload)
    })

    await ajs.track('My event', {
      banana: 'phone',
    })

    expect(called).toBe(true)
  })
})

describe('pageDefaults', () => {
  const el = document.createElement('link')
  el.setAttribute('rel', 'canonical')

  beforeEach(() => {
    el.setAttribute('href', '')
    document.clear()
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('handles no canonical links', () => {
    const defs = pageDefaults()
    expect(defs.url).not.toBeNull()
  })

  it('handles canonical links', () => {
    el.setAttribute('href', 'http://www.segment.local')
    document.body.appendChild(el)
    const defs = pageDefaults()
    expect(defs.url).toEqual('http://www.segment.local')
  })

  it('handles canonical links with a path', () => {
    el.setAttribute('href', 'http://www.segment.local/test')
    document.body.appendChild(el)
    const defs = pageDefaults()
    expect(defs.url).toEqual('http://www.segment.local/test')
    expect(defs.path).toEqual('/test')
  })

  it('handles canonical links with search params in the url', () => {
    el.setAttribute('href', 'http://www.segment.local?test=true')
    document.body.appendChild(el)
    const defs = pageDefaults()
    expect(defs.url).toEqual('http://www.segment.local?test=true')
  })
})
