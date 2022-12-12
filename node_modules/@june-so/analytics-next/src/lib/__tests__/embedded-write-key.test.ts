import { embeddedWriteKey } from '../embedded-write-key'

it('it guards against undefined', () => {
  expect(embeddedWriteKey()).toBe(undefined)
})

it('it returns undefined when default parameter is set', () => {
  window.analyticsWriteKey = '__WRITE_KEY__'
  expect(embeddedWriteKey()).toBe(undefined)
})

it('it returns the write key when the key is set properly', () => {
  window.analyticsWriteKey = 'abc_123_write_key'
  expect(embeddedWriteKey()).toBe('abc_123_write_key')
})
