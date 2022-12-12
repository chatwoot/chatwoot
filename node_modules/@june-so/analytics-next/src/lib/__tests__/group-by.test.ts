import { groupBy } from '../group-by'

describe('groupBy', () => {
  it('groups a collection by key', () => {
    const collection = [
      {
        id: 'go',
        type: 'server',
      },
      {
        id: 'ruby',
        type: 'server',
      },
      {
        id: 'js',
        type: 'browser',
      },
      {
        id: 'react',
        type: 'app',
      },
    ]

    expect(groupBy(collection, 'type')).toEqual({
      app: [
        {
          id: 'react',
          type: 'app',
        },
      ],
      browser: [
        {
          id: 'js',
          type: 'browser',
        },
      ],
      server: [
        {
          id: 'go',
          type: 'server',
        },
        {
          id: 'ruby',
          type: 'server',
        },
      ],
    })
  })

  it('accepts a function', () => {
    const collection = [
      {
        id: 1,
        type: 'server',
      },
      {
        id: 2,
        type: 'server',
      },
      {
        id: 3,
        type: 'browser',
      },
      {
        id: 4,
        type: 'app',
      },
    ]

    const oddEven = groupBy(collection, (c) =>
      c.id % 2 === 0 ? 'even' : 'odd'
    )
    expect(oddEven).toEqual({
      even: [
        {
          id: 2,
          type: 'server',
        },
        {
          id: 4,
          type: 'app',
        },
      ],
      odd: [
        {
          id: 1,
          type: 'server',
        },
        {
          id: 3,
          type: 'browser',
        },
      ],
    })
  })
})
