const fetch = jest.fn()

jest.mock('unfetch', () => {
  return fetch
})

import batch from '../batched-dispatcher'

const fatEvent = {
  _id: '609c0e91fe97b680e384d6e4',
  index: 5,
  guid: 'ca7fac24-41c9-45db-bc53-59b544e43943',
  isActive: false,
  balance: '$2,603.43',
  picture: 'http://placehold.it/32x32',
  age: 36,
  eyeColor: 'blue',
  name: 'Myers Hoover',
  gender: 'male',
  company: 'SILODYNE',
  email: 'myershoover@silodyne.com',
  phone: '+1 (986) 580-3562',
  address: '240 Ryder Avenue, Belva, Nebraska, 929',
  about:
    'Non eu nulla exercitation consectetur reprehenderit culpa mollit non consectetur magna tempor. Do et duis occaecat eu culpa dolor elit et est pariatur qui. Veniam dolore amet minim veniam quis esse. Aute commodo sint officia velit dolor. Sit enim nisi eu exercitation dolore nulla dolor occaecat. Sunt eu pariatur reprehenderit ipsum et nulla cillum culpa ea.\r\n',
  registered: '2019-04-13T09:29:21 +05:00',
  latitude: 68.879515,
  longitude: -46.670697,
  tags: ['magna', 'ex', 'nostrud', 'mollit', 'laborum', 'exercitation', 'sit'],
  friends: [
    {
      id: 0,
      name: 'Lynn Brock',
    },
    {
      id: 1,
      name: 'May Hull',
    },
    {
      id: 2,
      name: 'Elena Henderson',
    },
  ],
  greeting: 'Hello, Myers Hoover! You have 5 unread messages.',
  favoriteFruit: 'strawberry',
}

describe('Batching', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    jest.restoreAllMocks()
  })

  afterEach(() => {
    window.close()
  })

  it('does not send requests right away', async () => {
    const { dispatch } = batch(`https://api.segment.io`)

    await dispatch(`https://api.june.so/sdk/t`, {
      hello: 'world',
    })

    expect(fetch).not.toHaveBeenCalled()
  })

  it('sends requests after a batch limit is hit', async () => {
    const { dispatch } = batch(`https://api.segment.io`, {
      size: 3,
    })

    await dispatch(`https://api.june.so/sdk/t`, {
      event: 'first',
    })
    expect(fetch).not.toHaveBeenCalled()

    await dispatch(`https://api.june.so/sdk/t`, {
      event: 'second',
    })
    expect(fetch).not.toHaveBeenCalled()

    await dispatch(`https://api.june.so/sdk/t`, {
      event: 'third',
    })

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        "https://https://api.segment.io/b",
        Object {
          "body": "{\\"batch\\":[{\\"event\\":\\"first\\"},{\\"event\\":\\"second\\"},{\\"event\\":\\"third\\"}]}",
          "headers": Object {
            "Content-Type": "application/json",
          },
          "method": "post",
        },
      ]
    `)
  })

  it('sends requests if the size of events exceeds tracking API limits', async () => {
    const { dispatch } = batch(`https://api.segment.io`, {
      size: 600,
    })

    // fatEvent is about ~1kb in size
    for (let i = 0; i < 250; i++) {
      await dispatch(`https://api.june.so/sdk/t`, {
        event: 'fat event',
        properties: fatEvent,
      })
    }
    expect(fetch).not.toHaveBeenCalled()

    for (let i = 0; i < 250; i++) {
      await dispatch(`https://api.june.so/sdk/t`, {
        event: 'fat event',
        properties: fatEvent,
      })
    }

    // still called, even though our batch limit is 600 events
    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it('sends requests when the timeout expires', async () => {
    jest.useFakeTimers()

    const { dispatch } = batch(`https://api.segment.io`, {
      size: 100,
      timeout: 10000, // 10 seconds
    })

    await dispatch(`https://api.june.so/sdk/t`, {
      event: 'first',
    })
    expect(fetch).not.toHaveBeenCalled()

    await dispatch(`https://api.june.so/sdk/i`, {
      event: 'second',
    })

    jest.advanceTimersByTime(11000) // 11 seconds

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        "https://https://api.segment.io/b",
        Object {
          "body": "{\\"batch\\":[{\\"event\\":\\"first\\"},{\\"event\\":\\"second\\"}]}",
          "headers": Object {
            "Content-Type": "application/json",
          },
          "method": "post",
        },
      ]
    `)
  })

  it('clears the buffer between flushes', async () => {
    jest.useFakeTimers()

    const { dispatch } = batch(`https://api.segment.io`, {
      size: 100,
      timeout: 10000, // 10 seconds
    })

    await dispatch(`https://api.june.so/sdk/t`, {
      event: 'first',
    })

    jest.advanceTimersByTime(11000) // 11 seconds

    await dispatch(`https://api.june.so/sdk/i`, {
      event: 'second',
    })

    jest.advanceTimersByTime(11000) // 11 seconds

    expect(fetch).toHaveBeenCalledTimes(2)

    expect(fetch.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        "https://https://api.segment.io/b",
        Object {
          "body": "{\\"batch\\":[{\\"event\\":\\"first\\"}]}",
          "headers": Object {
            "Content-Type": "application/json",
          },
          "method": "post",
        },
      ]
    `)

    expect(fetch.mock.calls[1]).toMatchInlineSnapshot(`
      Array [
        "https://https://api.segment.io/b",
        Object {
          "body": "{\\"batch\\":[{\\"event\\":\\"second\\"}]}",
          "headers": Object {
            "Content-Type": "application/json",
          },
          "method": "post",
        },
      ]
    `)
  })

  describe('on unload', () => {
    let unloadHandler: Function | undefined = undefined

    beforeEach(() => {
      jest
        .spyOn(window, 'addEventListener')
        .mockImplementation((evt, handler) => {
          if (evt === 'beforeunload') {
            unloadHandler = handler as Function
          }
        })
    })

    it('flushes the batch', async () => {
      const { dispatch } = batch(`https://api.segment.io`)

      await dispatch(`https://api.june.so/sdk/t`, {
        hello: 'world',
      })

      await dispatch(`https://api.june.so/sdk/t`, {
        bye: 'world',
      })

      expect(fetch).not.toHaveBeenCalled()

      unloadHandler?.()

      expect(fetch).toHaveBeenCalledTimes(1)

      // any dispatch attempts after the page has unloaded are flushed immediately
      // this can happen if analytics.track is called right before page is navigated away
      dispatch(`https://api.june.so/sdk/t`, {
        afterlife: 'world',
      }).catch(console.error)

      // no queues, no waiting, instatneous
      expect(fetch).toHaveBeenCalledTimes(1)
    })

    it('flushes in batches of no more than 64kb', async () => {
      const { dispatch } = batch(`https://api.segment.io`, {
        size: 1000,
      })

      // fatEvent is about ~1kb in size
      for (let i = 0; i < 80; i++) {
        await dispatch(`https://api.june.so/sdk/t`, {
          event: 'fat event',
          properties: fatEvent,
        })
      }

      expect(fetch).not.toHaveBeenCalled()

      unloadHandler?.()
      expect(fetch).toHaveBeenCalledTimes(2)
    })
  })
})
