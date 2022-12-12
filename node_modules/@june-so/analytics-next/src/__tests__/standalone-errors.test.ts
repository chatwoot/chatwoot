import jsdom, { JSDOM } from 'jsdom'
import { AnalyticsBrowser, LegacySettings } from '../browser'
import { snippet } from '../tester/__fixtures__/segment-snippet'
import { pWhile } from '../lib/p-while'
import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { RemoteMetrics } from '../core/stats/remote-metrics'

const cdnResponse: LegacySettings = {
  integrations: {
    Zapier: {
      type: 'server',
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
}

const fetchSettings = Promise.resolve({
  json: () => Promise.resolve(cdnResponse),
})

jest.mock('unfetch', () => {
  return jest.fn()
})

describe('standalone bundle', () => {
  const segmentDotCom = `foo`

  let jsd: JSDOM

  beforeEach(() => {
    jest.restoreAllMocks()
    jest.resetAllMocks()

    jest.spyOn(console, 'warn').mockImplementationOnce(() => {})

    // @ts-ignore ignore Response required fields
    mocked(unfetch).mockImplementation((): Promise<Response> => fetchSettings)

    const html = `
    <!DOCTYPE html>
      <head>
        <script>
          ${snippet(segmentDotCom, true)}
        </script>
      </head>
      <body>
      </body>
    </html>
    `.trim()

    const virtualConsole = new jsdom.VirtualConsole()
    jsd = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://segment.com',
      virtualConsole,
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    const documentSpy = jest.spyOn(global, 'document', 'get')

    jest.spyOn(console, 'warn').mockImplementationOnce(() => {})

    windowSpy.mockImplementation(() => {
      return (jsd.window as unknown) as Window & typeof globalThis
    })

    documentSpy.mockImplementation(
      () => (jsd.window.document as unknown) as Document
    )
  })

  it('catches initialization errors and reports them', async () => {
    window.analyticsWriteKey = 'write_key_abc_123'
    const errorMessages: string[] = []
    const metrics: { metric: string; tags: string[] }[] = []

    jest.spyOn(console, 'error').mockImplementationOnce((...args) => {
      errorMessages.push(args.join(','))
    })

    jest
      .spyOn(RemoteMetrics.prototype, 'increment')
      .mockImplementationOnce((metric, tags) => {
        metrics.push({
          metric,
          tags,
        })
      })

    jest
      .spyOn(AnalyticsBrowser, 'standalone')
      .mockRejectedValueOnce(new Error('Ohhh nooo'))

    await import('../standalone')

    await pWhile(
      () => errorMessages.length === 0,
      () => {}
    )

    expect(metrics).toMatchInlineSnapshot(`
      Array [
        Object {
          "metric": "analytics_js.invoke.error",
          "tags": Array [
            "type:initialization",
            "message:Ohhh nooo",
            "name:Error",
            "host:segment.com",
            "wk:write_key_abc_123",
          ],
        },
      ]
    `)
    expect(errorMessages).toMatchInlineSnapshot(`
      Array [
        "[analytics.js],Failed to load Analytics.js,Error: Ohhh nooo",
      ]
    `)
  })
})
