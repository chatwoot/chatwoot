import { JSDOM } from 'jsdom'
import { Analytics } from '../../analytics'

const sleep = (time: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, time)
  })

async function resolveWhen(
  condition: () => boolean,
  timeout?: number
): Promise<void> {
  return new Promise((resolve, _reject) => {
    if (condition()) {
      resolve()
      return
    }

    const check = () =>
      setTimeout(() => {
        if (condition()) {
          resolve()
        } else {
          check()
        }
      }, timeout)

    check()
  })
}

describe('track helpers', () => {
  describe('trackLink', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let link: any
    let wrap: SVGSVGElement
    let svg: SVGAElement

    let analytics = new Analytics({ writeKey: 'foo' })
    let mockTrack = jest.spyOn(analytics, 'track')

    beforeEach(() => {
      analytics = new Analytics({ writeKey: 'foo' })

      // @ts-ignore
      global.jQuery = require('jquery')

      const jsd = new JSDOM('', {
        runScripts: 'dangerously',
        resources: 'usable',
      })
      document = jsd.window.document

      jest.spyOn(console, 'error').mockImplementationOnce(() => {})

      document.querySelector('html')!.innerHTML = `
      <html>
        <body>
          <a href='foo.com' id='foo'></a>
          <div id='bar'>
            <div>
              <a href='bar.com'></a>
            </div>
          </div>
        </body>
      </html>`

      link = document.getElementById('foo')
      wrap = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg = document.createElementNS('http://www.w3.org/2000/svg', 'a')
      wrap.appendChild(svg)
      document.body.appendChild(wrap)

      jest.spyOn(window, 'location', 'get').mockReturnValue({
        ...window.location,
      })

      mockTrack = jest.spyOn(analytics, 'track')

      // We need to mock the track function for the .catch() call not to break when testing
      // eslint-disable-next-line @typescript-eslint/unbound-method
      mockTrack.mockImplementation(Analytics.prototype.track)
    })

    it('should stay on same page with blank href', async () => {
      link.href = ''
      await analytics.trackLink(link!, 'foo')
      link.click()

      expect(mockTrack).toHaveBeenCalled()
      expect(window.location.href).toBe('http://localhost/')
    })

    it('should work with nested link', async () => {
      const nested = document.getElementById('bar')
      await analytics.trackLink(nested, 'foo')
      nested!.click()

      expect(mockTrack).toHaveBeenCalled()

      await resolveWhen(() => window.location.href === 'bar.com')
      expect(window.location.href).toBe('bar.com')
    })

    it('should make a track call', async () => {
      await analytics.trackLink(link!, 'foo')
      link.click()

      expect(mockTrack).toHaveBeenCalled()
    })

    it.only('should still navigate even if the track call fails', async () => {
      mockTrack.mockClear()

      let rejected = false
      mockTrack.mockImplementationOnce(() => {
        rejected = true
        return Promise.reject(new Error('boo!'))
      })

      const nested = document.getElementById('bar')
      await analytics.trackLink(nested, 'foo')
      nested!.click()

      await resolveWhen(() => rejected)
      await resolveWhen(() => window.location.href === 'bar.com')
      expect(window.location.href).toBe('bar.com')
    })

    it('should still navigate even if the track call times out', async () => {
      mockTrack.mockClear()

      let timedOut = false
      mockTrack.mockImplementationOnce(async () => {
        await sleep(600)
        timedOut = true
        return Promise.resolve() as any
      })

      const nested = document.getElementById('bar')
      await analytics.trackLink(nested, 'foo')
      nested!.click()

      await resolveWhen(() => window.location.href === 'bar.com')
      expect(window.location.href).toBe('bar.com')
      expect(timedOut).toBe(false)

      await resolveWhen(() => timedOut)
    })

    it('should accept a jquery object for an element', async () => {
      const $link = jQuery(link)
      await analytics.trackLink($link, 'foo')
      link.click()
      expect(mockTrack).toBeCalled()
    })

    it('accepts array of elements', async () => {
      const links = [link, link]
      await analytics.trackLink(links, 'foo')
      link.click()

      expect(mockTrack).toHaveBeenCalled()
    })

    it('should send an event and properties', async () => {
      await analytics.trackLink(link, 'event', { property: true })
      link.click()

      expect(mockTrack).toBeCalledWith('event', { property: true })
    })

    it('should accept an event function', async () => {
      function event(el: Element): string {
        return el.nodeName
      }
      await analytics.trackLink(link, event, { foo: 'bar' })
      link.click()

      expect(mockTrack).toBeCalledWith('A', { foo: 'bar' })
    })

    it('should accept a properties function', async () => {
      function properties(el: Record<string, string>): Record<string, string> {
        return { type: el.nodeName }
      }
      await analytics.trackLink(link, 'event', properties)
      link.click()

      expect(mockTrack).toBeCalledWith('event', { type: 'A' })
    })

    it('should load an href on click', async () => {
      link.href = '#test'
      await analytics.trackLink(link, 'foo')
      link.click()

      await resolveWhen(() => window.location.href === '#test')
      expect(global.window.location.href).toBe('#test')
    })

    it('should only navigate after the track call has been completed', async () => {
      link.href = '#test'
      await analytics.trackLink(link, 'foo')
      link.click()

      await resolveWhen(() => mockTrack.mock.calls.length === 1)
      await resolveWhen(() => window.location.href === '#test')

      expect(global.window.location.href).toBe('#test')
    })

    it('should support svg .href attribute', async () => {
      svg.setAttribute('href', '#svg')
      await analytics.trackLink(svg, 'foo')
      const clickEvent = new Event('click')
      svg.dispatchEvent(clickEvent)

      await resolveWhen(() => window.location.href === '#svg')
      expect(global.window.location.href).toBe('#svg')
    })

    it('should fallback to getAttributeNS', async () => {
      svg.setAttributeNS('http://www.w3.org/1999/xlink', 'href', '#svg')
      await analytics.trackLink(svg, 'foo')
      const clickEvent = new Event('click')
      svg.dispatchEvent(clickEvent)

      await resolveWhen(() => window.location.href === '#svg')
      expect(global.window.location.href).toBe('#svg')
    })

    it('should support xlink:href', async () => {
      svg.setAttribute('xlink:href', '#svg')
      await analytics.trackLink(svg, 'foo')
      const clickEvent = new Event('click')
      svg.dispatchEvent(clickEvent)

      await resolveWhen(() => window.location.href === '#svg')
      expect(global.window.location.href).toBe('#svg')
    })

    it('should not load an href for a link with a blank target', async () => {
      link.href = '/base/test/support/mock.html'
      link.target = '_blank'
      await analytics.trackLink(link, 'foo')
      link.click()

      await sleep(300)
      expect(global.window.location.href).not.toBe('#test')
    })
  })

  describe('trackForm', () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let form: any
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let submit: any

    const analytics = new Analytics({ writeKey: 'foo' })
    let mockTrack = jest.spyOn(analytics, 'track')

    beforeEach(() => {
      document.querySelector('html')!.innerHTML = `
      <html>
        <body>
          <form target='_blank' action='/base/test/support/mock.html' id='form'>
            <input type='submit' id='submit'/>
          </form>
        </body>
      </html>`
      form = document.getElementById('form')
      submit = document.getElementById('submit')

      // @ts-ignore
      global.jQuery = require('jquery')

      mockTrack = jest.spyOn(analytics, 'track')
      // eslint-disable-next-line @typescript-eslint/unbound-method
      mockTrack.mockImplementation(Analytics.prototype.track)
    })

    afterEach(() => {
      window.location.hash = ''
      document.body.removeChild(form)
    })

    it('should not error or send track event on null form', async () => {
      const form = document.getElementById('fake-form') as HTMLFormElement

      await analytics.trackForm(form, 'Signed Up', {
        plan: 'Premium',
        revenue: 99.0,
      })
      submit.click()
      expect(mockTrack).not.toBeCalled()
    })

    it('should trigger a track on a form submit', async () => {
      await analytics.trackForm(form, 'foo')
      submit.click()
      expect(mockTrack).toBeCalled()
    })

    it('should accept a jquery object for an element', async () => {
      await analytics.trackForm(form, 'foo')
      submit.click()
      expect(mockTrack).toBeCalled()
    })

    it('should not accept a string for an element', async () => {
      try {
        // @ts-expect-error
        await analytics.trackForm('foo')
        submit.click()
      } catch (e) {
        expect(e instanceof TypeError).toBe(true)
      }
      expect(mockTrack).not.toBeCalled()
    })

    it('should send an event and properties', async () => {
      await analytics.trackForm(form, 'event', { property: true })
      submit.click()
      expect(mockTrack).toBeCalledWith('event', { property: true })
    })

    it('should accept an event function', async () => {
      function event(): string {
        return 'event'
      }
      await analytics.trackForm(form, event, { foo: 'bar' })
      submit.click()
      expect(mockTrack).toBeCalledWith('event', { foo: 'bar' })
    })

    it('should accept a properties function', async () => {
      function properties(): Record<string, boolean> {
        return { property: true }
      }
      await analytics.trackForm(form, 'event', properties)
      submit.click()
      expect(mockTrack).toBeCalledWith('event', { property: true })
    })

    it('should call submit after a timeout', async (done) => {
      const submitSpy = jest.spyOn(form, 'submit')
      const mockedTrack = jest.fn()

      // eslint-disable-next-line @typescript-eslint/unbound-method
      mockedTrack.mockImplementation(Analytics.prototype.track)

      analytics.track = mockedTrack
      await analytics.trackForm(form, 'foo')

      submit.click()

      setTimeout(function () {
        expect(submitSpy).toHaveBeenCalled()
        done()
      }, 500)
    })

    it('should trigger an existing submit handler', async (done) => {
      form.addEventListener('submit', () => {
        done()
      })

      await analytics.trackForm(form, 'foo')
      submit.click()
    })

    it('should trigger an existing jquery submit handler', async (done) => {
      const $form = jQuery(form)

      $form.submit(function () {
        done()
      })

      await analytics.trackForm(form, 'foo')
      submit.click()
    })

    it('should track on a form submitted via jquery', async () => {
      const $form = jQuery(form)

      await analytics.trackForm(form, 'foo')
      $form.submit()

      expect(mockTrack).toBeCalled()
    })

    it('should trigger an existing jquery submit handler on a form submitted via jquery', async (done) => {
      const $form = jQuery(form)

      $form.submit(function () {
        done()
      })

      await analytics.trackForm(form, 'foo')
      $form.submit()
    })
  })
})
