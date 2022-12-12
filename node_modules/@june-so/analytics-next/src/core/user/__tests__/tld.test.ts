import cookie from 'js-cookie'
import { tld } from '../tld'
import assert from 'assert'

describe('topDomain', function () {
  beforeEach(() => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const cookies: Record<string, any> = {}

    // @ts-ignore
    jest.spyOn(cookie, 'set').mockImplementation((key, val, opts) => {
      const parts = opts?.domain?.split('.') ?? []
      if (parts[1] === 'co') return
      cookies[key] = val
      return val
    })

    // @ts-ignore
    jest.spyOn(cookie, 'get').mockImplementation((key) => {
      return cookies[key]
    })
  })

  it('should match the following urls', function () {
    assert.strictEqual(tld(new URL('http://www.google.com')), 'google.com')
    assert.strictEqual(
      tld(new URL('http://gist.github.com/calvinfo/some_file')),
      'github.com'
    )
    assert.strictEqual(tld(new URL('http://localhost:3000')), undefined)
    assert.strictEqual(
      tld(new URL('https://google.com:443/stuff')),
      'google.com'
    )
    assert.strictEqual(tld(new URL('http://dev:3000')), undefined)
    assert.strictEqual(tld(new URL('http://app.jut.io')), 'jut.io')
    assert.strictEqual(tld(new URL('http://app.segment.io')), 'segment.io')
  })
})
