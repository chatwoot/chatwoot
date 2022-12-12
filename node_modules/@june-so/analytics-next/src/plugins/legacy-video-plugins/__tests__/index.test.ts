import { JSDOM } from 'jsdom'
import { Analytics } from '../../../analytics'
import { loadLegacyVideoPlugins } from '../index'

beforeEach(async () => {
  jest.restoreAllMocks()
  jest.resetAllMocks()

  const html = `
    <!DOCTYPE html>
      <head>
        <script>
          'hi'
        </script>
      </head>
      <body>
      </body>
    </html>
    `.trim()

  const jsd = new JSDOM(html, {
    runScripts: 'dangerously',
    resources: 'usable',
  })

  const windowSpy = jest.spyOn(global, 'window', 'get')
  windowSpy.mockImplementation(() => {
    return (jsd.window as unknown) as Window & typeof globalThis
  })
})

describe(loadLegacyVideoPlugins.name, () => {
  it('attaches video plugins to ajs', async () => {
    console.warn = () => {}
    const ajs = new Analytics({
      writeKey: 'w_123',
    })

    await loadLegacyVideoPlugins(ajs)

    expect(ajs.plugins).toMatchInlineSnapshot(`
      Object {
        "VimeoAnalytics": [Function],
        "YouTubeAnalytics": [Function],
      }
    `)
  })
})
