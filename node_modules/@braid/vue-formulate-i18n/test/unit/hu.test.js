import * as locales from '@/locales'

// ✏️  Edit these to be the localized language
const locale = 'hu'

// ✏️  Edit your locale's name
describe('Hungarian translation', () => {
  it('exports a function', () => {
    expect(typeof locales[locale]).toBe('function')
  })

  it('calls extend on the formulate instance', () => {
    const instance = { extend: jest.fn() }
    locales[locale](instance)
    expect(instance.extend.mock.calls.length).toBe(1)
  })

  it('includes all the validation results that hungarian does', () => {
    const instance = { extend: jest.fn() }
    locales.hu(instance)
    locales[locale](instance)
    const hungarianMessages = Object.keys(instance.extend.mock.calls[0][0].locales.hu)
    const localizedMessages = Object.keys(instance.extend.mock.calls[1][0].locales[locale])
    expect(hungarianMessages).toEqual(localizedMessages)
  })
})
