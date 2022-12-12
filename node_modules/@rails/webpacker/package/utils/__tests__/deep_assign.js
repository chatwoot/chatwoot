/* global test expect */

const deepAssign = require('../deep_assign')

describe('deepAssign()', () => {
  test('deeply assigns nested properties', () => {
    const object = { foo: { bar: { } } }
    const path = 'foo.bar'
    const value = { x: 1, y: 2 }
    const expectation = { foo: { bar: { x: 1, y: 2 } } }
    expect(deepAssign(object, path, value)).toEqual(expectation)
  })

  test('allows assignment of a literal false', () => {
    const object = { foo: { bar: { } } }
    const path = 'foo.bar'
    const value = false
    const expectation = { foo: { bar: false } }
    expect(deepAssign(object, path, value)).toEqual(expectation)
  })

  test('does not allow assignment of other falsy values', () => {
    const object = { foo: { bar: { } } }
    const path = 'foo.bar'
    const values = [undefined, null, 0, '']

    values.forEach(value => {
      const expectation = new Error(`Value can't be ${value}`)
      expect(() => deepAssign(object, path, value)).toThrow(expectation)
    })
  })
})
