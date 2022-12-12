import { pickPrefix } from '../pickPrefix'

describe('pickPrefix', () => {
  it('strips a single prefix to creates an object', () => {
    const traits = pickPrefix('ajs_traits_', {
      /* eslint-disable @typescript-eslint/camelcase */
      ajs_traits_address: '12-123 St.',
      /* eslint-enable @typescript-eslint/camelcase */
    })

    const output = {
      address: '12-123 St.',
    }

    expect(traits).toEqual(output)
  })

  it('stripts multiple prefixes to create an object', () => {
    const traits = pickPrefix('ajs_traits_', {
      /* eslint-disable @typescript-eslint/camelcase */
      ajs_traits_address: '12-123 St.',
      ajs_traits_city: 'Vancouver',
      ajs_traits_province: 'BC',
      /* eslint-enable @typescript-eslint/camelcase */
    })

    const output = {
      address: '12-123 St.',
      city: 'Vancouver',
      province: 'BC',
    }

    expect(traits).toEqual(output)
  })
})
