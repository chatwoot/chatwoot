import jsdom, { JSDOM } from 'jsdom'
import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { LegacySettings } from '../browser'
import { onCSPError } from '../lib/csp-detection'
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

describe('CSP Detection', () => {
  const writeKey = `foo`

  let jsd: JSDOM
  let windowSpy: jest.SpyInstance
  let documentSpy: jest.SpyInstance

  const getClassic = (): HTMLScriptElement | undefined =>
    Array.from(document.scripts).find((s) =>
      s.getAttribute('src')?.includes('classic')
    )

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
          ${snippet(writeKey, true)}
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

  it('reverts to ajs classic in case of CSP errors', async () => {
    jest.spyOn(console, 'error').mockImplementationOnce(() => {})

    const handlers: Record<string, EventListener[]> = {}
    jest
      .spyOn(global.document, 'addEventListener')
      .mockImplementationOnce((e, handler) => {
        handlers[e] = (handlers[e] || []).concat(handler as EventListener)
      })

    await import('../standalone')

    handlers['securitypolicyviolation'].forEach((handler) => {
      handler({
        // @ts-ignore
        blockedURI: 'cdn.segment.com',
      })
    })

    await pWhile(
      () => getClassic() === undefined,
      () => {}
    )

    expect(getClassic()).toMatchInlineSnapshot(`
      <script
        src="https://cdn.foo.com/analytics.js/v1/foo/analytics.classic.js"
        status="loading"
        type="text/javascript"
      />
    `)
  })

  it('does not revert to classic when CSP error is report only', async () => {
    const ogScripts = Array.from(document.scripts)

    const warnSpy = jest.spyOn(console, 'warn')

    await onCSPError(({
      blockedURI: 'cdn.segment.com',
      disposition: 'report',
    } as unknown) as SecurityPolicyViolationEvent)

    expect(warnSpy).not.toHaveBeenCalled()
    expect(Array.from(document.scripts)).toEqual(ogScripts)
  })
})
