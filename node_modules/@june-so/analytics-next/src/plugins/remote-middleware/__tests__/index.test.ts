import { remoteMiddlewares } from '..'
import { Context } from '../../../core/context'
import jsdom from 'jsdom'

describe('Remote Middleware', () => {
  beforeEach(async () => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    const html = `
    <!DOCTYPE html>
      <head>
        <script>'you need me here'</script>
      </head>
      <body></body>
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

  it('ignores empty dictionaries', async () => {
    const md = await remoteMiddlewares(Context.system(), {
      integrations: {},
    })

    expect(md).toEqual([])
  })

  it('loads middleware that exist', async () => {
    const md = await remoteMiddlewares(Context.system(), {
      integrations: {},
      enabledMiddleware: {
        '@segment/analytics.js-middleware-braze-deduplicate': true,
      },
    })

    expect(md.length).toEqual(1)
    expect(md[0]).toMatchInlineSnapshot(`[Function]`)
  })

  it('ignores segment namespace', async () => {
    const md = await remoteMiddlewares(Context.system(), {
      integrations: {},
      enabledMiddleware: {
        '@segment/analytics.js-middleware-braze-deduplicate': true,
        'analytics.js-middleware-braze-deduplicate': true,
      },
    })

    expect(md.length).toEqual(2)
    expect(md[0]).toEqual(md[1])
  })

  it('loads middleware through remote script tags', async () => {
    await remoteMiddlewares(Context.system(), {
      integrations: {},
      enabledMiddleware: {
        '@segment/analytics.js-middleware-braze-deduplicate': true,
      },
    })

    const sources = Array.from(window.document.querySelectorAll('script'))
      .map((s) => s.src)
      .filter(Boolean)

    expect(sources).toMatchInlineSnapshot(`
      Array [
        "https://cdn.segment.com/next-integrations/middleware/analytics.js-middleware-braze-deduplicate/latest/analytics.js-middleware-braze-deduplicate.js.gz",
      ]
    `)
  })

  it('ignores middleware that do not exist', async () => {
    jest.spyOn(global.console, 'error').mockImplementation()

    const ctx = Context.system()
    const md = await remoteMiddlewares(ctx, {
      integrations: {},
      enabledMiddleware: {
        '@segment/analytics.js-middleware-braze-deduplicate': true,
        '@segment/analytics.js-middleware-that-does-not-exist': true,
      },
    })

    expect(md.length).toEqual(1)
    expect(md[0]).toMatchInlineSnapshot(`[Function]`)

    expect(ctx.logs().map((l) => l.message)).toMatchInlineSnapshot(`
      Array [
        [Error: Failed to load https://cdn.segment.com/next-integrations/middleware/analytics.js-middleware-that-does-not-exist/latest/analytics.js-middleware-that-does-not-exist.js.gz],
      ]
    `)
  })
})
