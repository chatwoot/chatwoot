import jsdom, { JSDOM } from 'jsdom'
import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { LegacySettings } from '../browser'
import { pWhile } from '../lib/p-while'
import { snippet } from '../tester/__fixtures__/segment-snippet'

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
  let windowSpy: jest.SpyInstance
  let documentSpy: jest.SpyInstance

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

    windowSpy = jest.spyOn(global, 'window', 'get')
    documentSpy = jest.spyOn(global, 'document', 'get')

    jest.spyOn(console, 'warn').mockImplementationOnce(() => {})

    windowSpy.mockImplementation(() => {
      return (jsd.window as unknown) as Window & typeof globalThis
    })

    documentSpy.mockImplementation(
      () => (jsd.window.document as unknown) as Document
    )
  })

  it('loads AJS on execution', async () => {
    await import('../standalone')

    await pWhile(
      () => window.analytics?.initialized !== true,
      () => {}
    )

    expect(window.analytics).not.toBeUndefined()
    expect(window.analytics.initialized).toBe(true)
  })
})
