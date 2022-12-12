import { backoff } from '../backoff'

describe('backoff', () => {
  it('increases with the number of attempts', () => {
    expect(backoff({ attempt: 1 })).toBeGreaterThan(1000)
    expect(backoff({ attempt: 2 })).toBeGreaterThan(2000)
    expect(backoff({ attempt: 3 })).toBeGreaterThan(3000)
    expect(backoff({ attempt: 4 })).toBeGreaterThan(4000)
  })

  it('accepts a max timeout', () => {
    expect(backoff({ attempt: 1, maxTimeout: 3000 })).toBeGreaterThan(1000)
    expect(backoff({ attempt: 3, maxTimeout: 3000 })).toBeLessThanOrEqual(3000)
    expect(backoff({ attempt: 4, maxTimeout: 3000 })).toBeLessThanOrEqual(3000)
  })

  it('accepts a growth factor', () => {
    const f2 = backoff({ attempt: 2, factor: 2 })
    const f3 = backoff({ attempt: 2, factor: 3 })

    expect(f3).toBeGreaterThan(f2)
  })
})
