import { JSDOM } from 'jsdom'
import { Analytics } from '../analytics'
// @ts-ignore loadLegacySettings mocked dependency is accused as unused
import { AnalyticsBrowser } from '../browser'
import { TEST_WRITEKEY } from './test-writekeys'

const writeKey = TEST_WRITEKEY

describe('queryString', () => {
  let jsd: JSDOM

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

    jsd = new JSDOM(html, {
      runScripts: 'dangerously',
      resources: 'usable',
      url: 'https://localhost',
    })

    const windowSpy = jest.spyOn(global, 'window', 'get')
    windowSpy.mockImplementation(
      () => (jsd.window as unknown) as Window & typeof globalThis
    )
  })

  it('applies query string logic if window.location.search is present', async () => {
    jest.mock('../analytics')
    const mockQueryString = jest
      .fn()
      .mockImplementation(() => Promise.resolve())
    Analytics.prototype.queryString = mockQueryString

    jsd.reconfigure({
      url: 'https://localhost/?ajs_id=123',
    })

    await AnalyticsBrowser.load({ writeKey })
    expect(mockQueryString).toHaveBeenCalledWith('?ajs_id=123')
  })

  it('applies query string logic if window.location.hash is present', async () => {
    jest.mock('../analytics')
    const mockQueryString = jest
      .fn()
      .mockImplementation(() => Promise.resolve())
    Analytics.prototype.queryString = mockQueryString

    jsd.reconfigure({
      url: 'https://localhost/#/?ajs_id=123',
    })

    await AnalyticsBrowser.load({ writeKey })
    expect(mockQueryString).toHaveBeenCalledWith('?ajs_id=123')

    jsd.reconfigure({
      url: 'https://localhost/#about?ajs_id=123',
    })

    await AnalyticsBrowser.load({ writeKey })
    expect(mockQueryString).toHaveBeenCalledWith('?ajs_id=123')
  })

  it('applies query string logic if window.location.hash is present in different formats', async () => {
    jest.mock('../analytics')
    const mockQueryString = jest
      .fn()
      .mockImplementation(() => Promise.resolve())
    Analytics.prototype.queryString = mockQueryString

    jsd.reconfigure({
      url: 'https://localhost/#about?ajs_id=123',
    })

    await AnalyticsBrowser.load({ writeKey })
    expect(mockQueryString).toHaveBeenCalledWith('?ajs_id=123')
  })
})
