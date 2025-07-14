import * as Store from '../store'
import transform from '../transformers'

import * as simple from '../../fixtures/simple.json'
import * as many from '../../fixtures/manyProperties.json'

let simpleEvent
let manyPropertiesEvent
let transformer: Store.Transformer

// Sample transformer config: `[]`
beforeEach(() => {
  simpleEvent = JSON.parse(JSON.stringify(simple))
  manyPropertiesEvent = JSON.parse(JSON.stringify(many))
  transformer = {
    type: 'drop',
    config: null,
  }
})

describe('error handling and basic checks', () => {
  test('throws an error on an invalid transform type', () => {
    transformer.config = {}
    transformer.type = 'not_a_transform'

    expect(() => {
      transform({}, [transformer])
    }).toThrow()
  })

  test('throws an error if config is null and type is not drop', () => {
    transformer.type = 'drop_properties'
    expect(() => {
      transform({}, [transformer])
    }).toThrow()

    transformer.type = 'allow_properties'
    expect(() => {
      transform({}, [transformer])
    }).toThrow()

    transformer.type = 'sample_event'
    expect(() => {
      transform({}, [transformer])
    }).toThrow()
  })

  test('does not throw an error if config is null and type is drop', () => {
    // Using default transformer
    expect(transform({}, [transformer])).toBe(null)
  })
})

describe('drop', () => {
  beforeEach(() => {
    transformer.type = 'drop'
    transformer.config = null
  })

  test('drop should return null to any payload', () => {
    expect(transform({}, [transformer])).toBe(null)
    expect(transform(simpleEvent, [transformer])).toBe(null)
    expect(transform(manyPropertiesEvent, [transformer])).toBe(null)
    expect(transform('I like cheese.', [transformer])).toBe(null)
  })
})

describe('drop_properties', () => {
  beforeEach(() => {
    transformer.type = 'drop_properties'
    transformer.config = { drop: { properties: ['email', 'phoneNumber'] } }
  })

  test('drop_properties should mutate the input object', () => {
    simpleEvent.properties.phoneNumber = '867-5309'
    transform(simpleEvent, [transformer])

    expect(simpleEvent.properties.phoneNumber).toBeUndefined()
  })

  test('drop_properties should drop top-level fields', () => {
    simpleEvent.someTopLevelField = 'test'
    transformer.config = { drop: { '': ['someTopLevelField'] } }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.someTopLevelField).toBeUndefined()
  })

  test('drop_properties should drop nested fields', () => {
    simpleEvent.nest1 = {
      nest2: {
        nest3: {
          nest4: {
            nest5: 'hai :3',
          },
        },
      },
    }
    transformer.config = { drop: { 'nest1.nest2.nest3.nest4': ['nest5'] } }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.nest1.nest2.nest3.nest4.nest5).toBeUndefined()
  })

  test('drop_properties should work quickly even on huge objects', () => {
    manyPropertiesEvent.nest1 = {
      nest2: {
        nest3: {
          nest4: {
            nest5: 'hai :3',
          },
        },
      },
    }
    transformer.config = { drop: { 'nest1.nest2.nest3.nest4': ['nest5'] } }

    transform(manyPropertiesEvent, [transformer])
    expect(manyPropertiesEvent.nest1.nest2.nest3.nest4.nest5).toBeUndefined()
  }, 500)
})

describe('allow_properties', () => {
  beforeEach(() => {
    transformer.type = 'allow_properties'
    transformer.config = { allow: { properties: ['email'] } }
  })

  test('allow_properties should mutate the input object', () => {
    simpleEvent.properties.phoneNumber = '867-5309'

    transform(simpleEvent, [transformer])
    expect(simpleEvent.properties.phoneNumber).toBeUndefined()
  })

  test('allow_properties should work on the top-level object (ill-advised as it is)', () => {
    simpleEvent.onlyAllowedProp = 'test'
    transformer.config = { allow: { '': ['onlyAllowedProp'] } }
    expect(Object.keys(simpleEvent).length > 1)

    transform(simpleEvent, [transformer])
    expect(simpleEvent).toStrictEqual({ onlyAllowedProp: 'test' })
  })

  test('allow_properties should drop nested fields and only in those fields', () => {
    simpleEvent.nest1 = {
      nest2: {
        nest3: {
          nest4: {
            nest5: 'hai :3',
            nest6: 'bye ;_;',
          },
        },
      },
    }
    transformer.config = { allow: { 'nest1.nest2.nest3.nest4': ['nest5'] } }
    const originalPropCount = Object.keys(simpleEvent).length

    transform(simpleEvent, [transformer])
    expect(originalPropCount === Object.keys(simpleEvent).length)
    expect(simpleEvent.nest1.nest2.nest3.nest4).toStrictEqual({ nest5: 'hai :3' })
  })

  test('drop_properties should work quickly even on huge objects', () => {
    manyPropertiesEvent.nest1 = {
      nest2: {
        nest3: {
          nest4: {
            nest5: 'hai :3',
            nest6: 'bye ;_;',
          },
        },
      },
    }
    transformer.config = { allow: { 'nest1.nest2.nest3.nest4': ['nest5'] } }
    const originalPropCount = Object.keys(manyPropertiesEvent).length

    transform(manyPropertiesEvent, [transformer])
    expect(originalPropCount === Object.keys(manyPropertiesEvent).length)
    expect(manyPropertiesEvent.nest1.nest2.nest3.nest4).toStrictEqual({ nest5: 'hai :3' })
  }, 500)
})

describe('sample_event', () => {
  beforeEach(() => {
    transformer.type = 'sample_event'
    transformer.config = { sample: { percent: 0.0, path: '' } }
  })

  test('sample_event always returns false if percent is 0% or less', () => {
    // Run many times to ensure same results each time
    for (let i = 0; i < 1000; i++) {
      simpleEvent = JSON.parse(JSON.stringify(simple))

      const payload = transform(simpleEvent, [transformer])
      expect(payload).toBeNull()
    }
  })

  test('sample_event always returns true if percent is 100% or more', () => {
    transformer.config = { sample: { percent: 1.01, path: '' } }

    for (let i = 0; i < 1000; i++) {
      simpleEvent = JSON.parse(JSON.stringify(simple))

      const payload = transform(simpleEvent, [transformer])
      expect(payload).toStrictEqual(simpleEvent)
    }
  })

  test("sample_event allows sampling based off a JSON path's value", () => {
    transformer.config = { sample: { percent: 0.5, path: 'propToSampleOffOf' } }
    simpleEvent.propToSampleOffOf = 'abcd'

    // Check for no throw - value (null or unfiltered) isn't important in this test.
    expect(transform(simpleEvent, [transformer])).toBeDefined()
  })

  test('sample_event returns the same result every time for a given path:value', () => {
    transformer.config = { sample: { percent: 0.5, path: 'propToSampleOffOf' } }
    for (let i = 0; i < 100; i++) {
      simpleEvent.propToSampleOffOf = Math.random()
      const firstResult = transform(simpleEvent, [transformer])
      for (let j = 0; j < 100; j++) {
        const repeatedResult = transform(simpleEvent, [transformer])
        expect(repeatedResult).toStrictEqual(firstResult)
      }
    }
  })

  test('sample_event returns the same result for a given path:value for any percent subset', () => {
    // If a given path:value returns true starting at 0.30, then it should continue to return true for 0.31
    // through 1. Thusly, a selection of 30% of values in a field will be a subset of a selection of 60%,
    // and so on.

    // Create a field, up the % until we get a non-null result, then assert that it remains non-null (truthy)
    // from then on.
    for (let i = 0; i < 100; i++) {
      simpleEvent.propToSampleOffOf = Math.random()
      let hasBeenDefined = false
      for (let percent = 0; percent <= 1.01; percent += 0.01) {
        transformer.config = { sample: { percent, path: 'propToSampleOffOf' } }
        const result = transform(simpleEvent, [transformer])
        if (hasBeenDefined) {
          expect(result).toBeTruthy()
        } else {
          if (result !== null) {
            hasBeenDefined = true
          }
        }
      }
    }
  })
})

describe('map_properties', () => {
  beforeEach(() => {
    transformer.type = 'map_properties'
    transformer.config = {
      map: {
        mapMe: { set: true },
      },
    }
  })

  test('map_properties should mutate the input object', () => {
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe === true)
  })

  test('map_properties can copy fields from one place to another without deleting the origin', () => {
    simpleEvent.copyMe = 'Beam me up, Scotty!'
    transformer.config = {
      map: {
        mapMe: { copy: 'copyMe' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('Beam me up, Scotty!')
    expect(simpleEvent.copyMe).toBe('Beam me up, Scotty!')
  })

  test('map_properties does not copy if there is no field to copy', () => {
    transformer.config = {
      map: {
        mapMe: { copy: 'copyMe' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBeUndefined()
    expect(simpleEvent.copyMe).toBeUndefined()
  })

  test('map_properties can move fields from one place to another and delete the origin', () => {
    simpleEvent.moveMe = 'I like to move it, move it...'
    transformer.config = {
      map: {
        mapMe: { move: 'moveMe' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('I like to move it, move it...')
    expect(simpleEvent.moveMe).toBeUndefined()
  })

  test('map_properties does not move if there is no field to move', () => {
    transformer.config = {
      map: {
        mapMe: { move: 'moveMe' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBeUndefined()
    expect(simpleEvent.moveMe).toBeUndefined()
  })

  test('map_properties can set fields that are not yet set', () => {
    transformer.config = {
      map: {
        mapMe: { set: 'Someone set us up the bomb' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('Someone set us up the bomb')
  })

  test('map_properties can set fields that are already set', () => {
    simpleEvent.mapMe = 'This is not the message you are looking for'
    transformer.config = {
      map: {
        mapMe: { set: 'Someone set us up the bomb' },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('Someone set us up the bomb')
  })

  test('map_properties can set falsey values', () => {
    transformer.config = {
      map: {
        mapMe: { set: null },
      },
    }

    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBeNull()

    transformer.config = {
      map: {
        mapMe: { set: false },
      },
    }
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe(false)

    transformer.config = {
      map: {
        mapMe: { set: 0 },
      },
    }
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe(0)

    transformer.config = {
      map: {
        mapMe: { set: [] },
      },
    }
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toStrictEqual([])
  })

  test('map_properties can convert values to strings', () => {
    transformer.config = {
      map: {
        mapMe: { to_string: true },
      },
    }

    simpleEvent.mapMe = 1234
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('1234')

    simpleEvent.mapMe = null
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('null')

    simpleEvent.mapMe = []
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toStrictEqual([])

    simpleEvent.mapMe = undefined
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('undefined')

    simpleEvent.mapMe = { foo: 'bar' }
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toStrictEqual({ foo: 'bar' })

    simpleEvent.mapMe = 'already a string'
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('already a string')

    simpleEvent.mapMe = false
    transform(simpleEvent, [transformer])
    expect(simpleEvent.mapMe).toBe('false')
  })
})
