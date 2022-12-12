import {
  resolveArguments,
  resolvePageArguments,
  resolveUserArguments,
  Callback,
  resolveAliasArguments,
} from '../'
import { User } from '../../user'

const bananaPhone = {
  banana: 'phone',
}

const baseOptions = {
  integrations: {
    amplitude: false,
  },
}

describe(resolveArguments, () => {
  test('resolves all args', () => {
    const callback = jest.fn()

    const [event, props, options, cb] = resolveArguments(
      'Test Event',
      bananaPhone,
      {
        integrations: {
          amplitude: false,
        },
      },
      callback
    )

    expect(event).toEqual('Test Event')
    expect(props).toEqual(bananaPhone)
    expect(options).toEqual({
      integrations: {
        amplitude: false,
      },
    })
    expect(cb).toEqual(callback)
  })

  describe('event as string', () => {
    test('event, props', () => {
      const [event, props, options, cb] = resolveArguments(
        'Test Event',
        bananaPhone
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(options).toEqual({})
      expect(cb).toBeUndefined()
    })

    test('event, props, options', () => {
      const [event, props, options, cb] = resolveArguments(
        'Test Event',
        bananaPhone,
        {
          integrations: {
            intercom: false,
          },
        }
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(options).toEqual({
        integrations: {
          intercom: false,
        },
      })
      expect(cb).toBeUndefined()
    })

    test('event, props, callback', () => {
      const fn = jest.fn()

      const [event, props, options, cb] = resolveArguments(
        'Test Event',
        bananaPhone,
        fn
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(options).toEqual({})
      expect(cb).toEqual(fn)
    })

    test('event, callback', () => {
      const fn = jest.fn()

      const [event, props, options, cb] = resolveArguments('Test Event', fn)

      expect(event).toEqual('Test Event')
      expect(props).toEqual({})
      expect(options).toEqual({})
      expect(cb).toEqual(fn)
    })
  })

  describe('event as object', () => {
    test('requires an event name', () => {
      expect(() =>
        resolveArguments({
          type: 'track',
        })
      ).toThrowErrorMatchingInlineSnapshot(`"Event missing"`)
    })

    test('all args', () => {
      const fn = jest.fn()

      const [event, props, options, cb] = resolveArguments(
        {
          type: 'track',
          event: 'Test Event',
          properties: bananaPhone,
        },
        {
          integrations: {
            amplitude: false,
          },
        },
        fn
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(options).toEqual({
        integrations: {
          amplitude: false,
        },
      })
      expect(cb).toEqual(fn)
    })

    test('event, options', () => {
      const [event, props, options, cb] = resolveArguments(
        {
          type: 'track',
          event: 'Test Event',
          properties: bananaPhone,
        },
        {
          integrations: {
            amplitude: false,
          },
        }
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(options).toEqual({
        integrations: {
          amplitude: false,
        },
      })
      expect(cb).toBeUndefined()
    })

    test('event, callback', () => {
      const fn = jest.fn()
      const [event, props, options, cb] = resolveArguments(
        {
          type: 'track',
          event: 'Test Event',
          properties: bananaPhone,
        },
        fn
      )

      expect(event).toEqual('Test Event')
      expect(props).toEqual(bananaPhone)
      expect(cb).toEqual(fn)
      expect(options).toEqual({})
    })
  })
})

describe(resolvePageArguments, () => {
  test('should accept (category, name, properties, options, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'category',
      'name',
      bananaPhone,
      baseOptions,
      fn
    )

    expect(category).toEqual('category')
    expect(name).toEqual('name')
    expect(properties).toEqual(bananaPhone)
    expect(options).toEqual(baseOptions)
    expect(cb).toEqual(fn)
  })

  test('empty strings ("", "", "", { integrations })', () => {
    const [category, name, properties, options] = resolvePageArguments(
      '',
      '',
      null,
      {
        integrations: {
          Amplitude: {
            sessionId: '123',
          },
        },
      }
    )

    expect(category).toEqual('')
    expect(name).toEqual('')
    expect(properties).toEqual({})
    expect(options).toEqual({
      integrations: {
        Amplitude: {
          sessionId: '123',
        },
      },
    })
  })

  test('should accept (category, name, properties, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'category',
      'name',
      bananaPhone,
      fn
    )

    expect(category).toEqual('category')
    expect(name).toEqual('name')
    expect(properties).toEqual(bananaPhone)
    expect(cb).toEqual(fn)

    expect(options).toEqual({})
  })

  it('should accept (category, name, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'category',
      'name',
      fn
    )

    expect(category).toEqual('category')
    expect(name).toEqual('name')
    expect(properties).toEqual({})
    expect(cb).toEqual(fn)

    expect(options).toEqual({})
  })

  it('should accept (name, properties, options, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'name',
      bananaPhone,
      baseOptions,
      fn
    )

    expect(category).toEqual(null)
    expect(name).toEqual('name')
    expect(properties).toEqual(bananaPhone)
    expect(options).toEqual(baseOptions)
    expect(cb).toEqual(fn)
  })

  it('should accept (name, properties, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'name',
      bananaPhone,
      fn
    )

    expect(category).toEqual(null)
    expect(name).toEqual('name')
    expect(properties).toEqual(bananaPhone)
    expect(cb).toEqual(fn)
    expect(options).toEqual({})
  })

  it('should accept (name, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      'name',
      fn
    )

    expect(name).toEqual('name')
    expect(cb).toEqual(fn)

    expect(category).toEqual(null)
    expect(properties).toEqual({})
    expect(options).toEqual({})
  })

  it('should accept (properties, options, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      bananaPhone,
      baseOptions,
      fn
    )

    expect(cb).toEqual(fn)
    expect(properties).toEqual(bananaPhone)
    expect(options).toEqual(baseOptions)

    expect(name).toEqual(null)
    expect(category).toEqual(null)
  })

  it('should accept (properties, callback)', () => {
    const fn = jest.fn()
    const [category, name, properties, options, cb] = resolvePageArguments(
      bananaPhone,
      fn
    )

    expect(properties).toEqual(bananaPhone)
    expect(cb).toEqual(fn)

    expect(options).toEqual({})
    expect(name).toEqual(null)
    expect(category).toEqual(null)
  })
})

describe(resolveUserArguments, () => {
  let user: User
  let resolver: ReturnType<typeof resolveUserArguments>
  let fn: Callback

  const userTraits = {
    phone: '555 5555',
  }

  const uid = 'id'

  beforeEach(() => {
    user = new User()
    resolver = resolveUserArguments(user)
    fn = jest.fn()
  })

  it('should accept (id, traits, options, callback)', () => {
    const [id, traits, options, cb] = resolver(uid, userTraits, baseOptions, fn)

    expect(id).toEqual(uid)
    expect(traits).toEqual(userTraits)
    expect(options).toEqual(baseOptions)
    expect(cb).toEqual(fn)
  })

  it('should accept (id, traits, callback)', () => {
    const [id, traits, options, cb] = resolver(uid, userTraits, fn)

    expect(id).toEqual(uid)
    expect(traits).toEqual(userTraits)
    expect(cb).toEqual(fn)

    expect(options).toEqual({})
  })

  it('should accept (id, callback)', () => {
    const [id, traits, options, cb] = resolver(uid, fn)

    expect(id).toEqual(uid)
    expect(cb).toEqual(fn)

    expect(traits).toEqual({})
    expect(options).toEqual({})
  })

  it('should accept (traits, options, callback)', () => {
    user.identify('TestID')
    const [id, traits, options, cb] = resolver(userTraits, baseOptions, fn)

    expect(id).toEqual('TestID')
    expect(cb).toEqual(fn)
    expect(traits).toEqual(userTraits)
    expect(options).toEqual(baseOptions)
  })

  it('should accept (traits, callback)', () => {
    user.identify('TestID')
    const [id, traits, options, cb] = resolver(userTraits, fn)

    expect(id).toEqual('TestID')
    expect(traits).toEqual(userTraits)
    expect(cb).toEqual(fn)

    expect(options).toEqual({})
  })

  it('should accept (id, null, options)', () => {
    const [id, traits, options] = resolver(uid, null, baseOptions)
    expect(id).toEqual(uid)
    expect(traits).toEqual({})
    expect(options).toEqual(baseOptions)
  })

  it('should accept (id, traits)', () => {
    const [id, traits, options] = resolver(uid, userTraits)
    expect(id).toEqual(uid)
    expect(traits).toEqual(userTraits)
    expect(options).toEqual({})
  })
})

describe(resolveAliasArguments, () => {
  it('should accept (to, from, options, callback)', () => {
    const fn = jest.fn()
    const [to, from, options, cb] = resolveAliasArguments(
      'to',
      'from',
      {
        integrations: {
          intercom: false,
        },
      },
      fn
    )

    expect(to).toEqual('to')
    expect(from).toEqual('from')
    expect(options).toEqual({
      integrations: {
        intercom: false,
      },
    })
    expect(cb).toBe(fn)
  })

  it('should accept (to, options, callback)', () => {
    const fn = jest.fn()
    const [to, from, options, cb] = resolveAliasArguments(
      'to',
      {
        integrations: {
          intercom: false,
        },
      },
      fn
    )

    expect(to).toEqual('to')
    expect(from).toBeNull()
    expect(options).toEqual({
      integrations: {
        intercom: false,
      },
    })
    expect(cb).toBe(fn)
  })

  it('should accept (to, callback)', () => {
    const fn = jest.fn()
    const [to, from, options, cb] = resolveAliasArguments('to', fn)

    expect(to).toEqual('to')
    expect(from).toBeNull()
    expect(options).toEqual({})
    expect(cb).toBe(fn)
  })

  it('should accept (to, from, callback)', () => {
    const fn = jest.fn()
    const [to, from, options, cb] = resolveAliasArguments('to', 'from', fn)

    expect(to).toEqual('to')
    expect(from).toEqual('from')
    expect(options).toEqual({})
    expect(cb).toBe(fn)
  })
})
