import { transform, matches, Store } from '../index'

test('transform and matches are exported', () => {
  expect(transform).toBeTruthy()
  expect(matches).toBeTruthy()
})

test('we can use the exported transformer', () => {
  const result = transform(
    {
      removeMe: true,
      dontRemoveMe: true,
    },
    [
      {
        type: 'drop_properties',
        config: { drop: { '': ['removeMe'] } },
      },
    ]
  )

  expect(result.dontRemoveMe).toBeTruthy()
  expect(result.removeMe).toBeUndefined()
})

test('we can use the exported matcher', () => {
  // FQL: contains(email, ".com")
  let result = matches(
    {
      email: 'peter.richmond@segment.com',
    },
    {
      ir: `["contains", "email", {"value": ".com"}]`,
      type: 'fql',
    }
  )

  expect(result === true)

  result = matches(
    {
      email: 'peter.richmond@segment.NOPE',
    },
    {
      ir: `["contains", "email", {"value": ".com"}]`,
      type: 'fql',
    }
  )

  expect(result === false)
})

test('we can use the exported Store', () => {
  const routingRules = [
    {
      matchers: [
        {
          ir: '["=","event",{"value":"Test"}]',
          type: 'fql',
          config: { expr: 'event = "Test"' },
        },
      ],
      scope: 'destinations',
      target_type: 'workspace::project::destination',
      transformers: [[{ type: 'drop' }]],
      destinationName: 'Google Analytics',
    },
  ]

  const store = new Store(routingRules)

  let result = store.getRulesByDestinationName('Google Analytics')
  expect(result).toStrictEqual(routingRules)

  result = store.getRulesByDestinationName('Adobe Analytics')
  expect(result).toStrictEqual([])
})

test('we can use all exports to full evaluate a rule on a payload', () => {
  const routingRules = [
    {
      matchers: [
        {
          ir: '["=","event",{"value":"Test"}]',
          type: 'fql',
          config: { expr: 'event = "Test"' },
        },
      ],
      scope: 'destinations',
      target_type: 'workspace::project',
      transformers: [[{ type: 'drop' }]],
    },
  ]

  const store = new Store(routingRules)

  // Testing that it fetches rules without a destinationName as well
  const storeRules = store.getRulesByDestinationName('Google Analytics')

  const matchers = storeRules[0].matchers
  const transformers = storeRules[0].transformers

  const payloadToDrop = {
    event: 'Test',
  }

  const payloadToKeep = {
    event: 'Not Test',
  }

  // Payload that should drop
  if (matches(payloadToDrop, matchers[0])) {
    let payload = payloadToDrop
    for (const transformer of transformers) {
      payload = transform(payload, transformer)
    }
    expect(payload).toBeNull()
  } else {
    console.error('Matcher failed - expected a match!')
    expect(false)
  }

  if (matches(payloadToKeep, matchers[0])) {
    console.error('Matcher failed - expected no match!')
    expect(false)
  }
})
