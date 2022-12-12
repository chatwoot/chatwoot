import { mocked } from 'ts-jest/utils'
import { JSDOM } from 'jsdom'
import { AnalyticsBrowser, LegacySettings } from '../../../browser'

jest.mock('unfetch', () => {
  return jest.fn()
})

import unfetch from 'unfetch'

describe.skip('Remote Plugin Integration', () => {
  const window = global.window as any

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
      () => jsd.window as unknown as Window & typeof globalThis
    )

    const cdnResponse: LegacySettings = {
      integrations: {},
      remotePlugins: [
        // This may be a bit flaky
        // we should mock this file in case it becomes a problem
        // but I'd like to have a full integration test if possible
        {
          name: 'amplitude',
          url: 'https://ajs-next-integrations.s3-us-west-2.amazonaws.com/fab-5/amplitude-plugins.js',
          libraryName: 'amplitude-pluginsDestination',
          settings: {
            subscriptions: `[{"partnerAction":"sessionId","name":"SessionId","enabled":true,"subscribe":"type = \\"track\\"", "mapping":{}}]`,
          },
        },
      ],
    }

    // @ts-ignore mocking fetch is *hard*
    // @ts-ignore
    mocked(unfetch).mockImplementation(
      // @ts-ignore
      (): Promise<Response> =>
        // @ts-ignore
        Promise.resolve({
          json: () => Promise.resolve(cdnResponse),
        })
    )
  })

  it('loads remote plugins', async () => {
    await AnalyticsBrowser.load({
      writeKey: 'test-write-key',
    })

    // loaded remote plugin
    expect(window['amplitude-pluginsDestination']).not.toBeUndefined()
  })
})
