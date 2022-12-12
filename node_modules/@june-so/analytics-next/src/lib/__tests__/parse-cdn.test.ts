import { JSDOM, VirtualConsole } from 'jsdom'
import { getCDN } from '../parse-cdn'

function withTag(tag: string) {
  const html = `
    <!DOCTYPE html>
      <head>
        ${tag}
      </head>
      <body>
      </body>
    </html>
    `.trim()

  const virtualConsole = new VirtualConsole()
  const jsd = new JSDOM(html, {
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
}

beforeEach(async () => {
  jest.restoreAllMocks()
  jest.resetAllMocks()
})

it('detects the existing segment cdn', () => {
  withTag(`
    <script src="https://cdn.segment.com/analytics.js/v1/gA5MBlJXrtZaB5sMMZvCF6czfBcfzNO6/analytics.min.js" />
  `)
  expect(getCDN()).toMatchInlineSnapshot(`"https://cdn.segment.com"`)
})

it('detects custom cdns that match Segment in domain instrumentation patterns', () => {
  withTag(`
    <script src="https://my.cdn.domain/analytics.js/v1/gA5MBlJXrtZaB5sMMZvCF6czfBcfzNO6/analytics.min.js" />
  `)
  expect(getCDN()).toMatchInlineSnapshot(`"https://my.cdn.domain"`)
})

it('falls back to Segment if CDN is used as a proxy', () => {
  withTag(`
    <script src="https://my.cdn.proxy/custom-analytics.min.js" />
  `)
  expect(getCDN()).toMatchInlineSnapshot(`"https://cdn.segment.com"`)
})

it('falls back to Segment if the script is not at all present on the page', () => {
  withTag('')
  expect(getCDN()).toMatchInlineSnapshot(`"https://cdn.segment.com"`)
})
