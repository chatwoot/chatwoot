import { asPromise } from '../as-promise'

describe('asPromise', () => {
  it('wraps a value so it can be awaited', async () => {
    expect(await asPromise(1)).toBe(1)
  })

  it('keeps promises as promises', async () => {
    expect(await asPromise(Promise.resolve(1))).toBe(1)
  })

  it('works with functions', async () => {
    expect((await asPromise(() => 1))()).toBe(1)
  })
})
