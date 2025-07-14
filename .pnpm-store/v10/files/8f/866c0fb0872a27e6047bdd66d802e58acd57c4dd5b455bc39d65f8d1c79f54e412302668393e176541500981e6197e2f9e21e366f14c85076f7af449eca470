import matches from '../matchers'
import * as Store from '../store'

import * as simple from '../../fixtures/simple.json'
import * as many from '../../fixtures/manyProperties.json'

let simpleEvent
let manyPropertiesEvent
let matcher: Store.Matcher
beforeEach(() => {
  simpleEvent = JSON.parse(JSON.stringify(simple))
  manyPropertiesEvent = JSON.parse(JSON.stringify(many))
  matcher = {
    ir: 'true',
    type: 'fql',
  }
})

describe('error handling and basic checks', () => {
  test('throws on a bad IR', () => {
    ; (matcher.ir = 'Invalid//**[]""""json'),
      expect(() => {
        matches({}, matcher)
      }).toThrow()
  })

  test('throws on a bad Type', () => {
    matcher.type = "it's free real estate"

    expect(() => {
      matches({}, matcher)
    }).toThrow()
  })

  test('returns true and accepts no IR if the type is All', () => {
    matcher.ir = ''
    matcher.type = 'all'

    expect(matches({}, matcher)).toBe(true)
  })

  test('returns false on an empty IR for FQL', () => {
    matcher.ir = ''

    expect(matches({}, matcher)).toBe(false)
  })

  test('can handle large payloads', () => {
    // FQL: "trueValue"
    matcher.ir = '"trueValue"'

    manyPropertiesEvent.trueValue = true
    expect(matches(manyPropertiesEvent, matcher)).toBe(true)
  })

  test('can parse paths', () => {
    // FQL: "trueValue"
    matcher.ir = '"trueValue"'

    simpleEvent.trueValue = true
    expect(matches(simpleEvent, matcher)).toBe(true)
  })

  test('can parse values', () => {
    // FQL: true
    matcher.ir = '{"value": true}'

    expect(matches(simpleEvent, matcher)).toBe(true)
  })

  test('returns false if the fql returns a non-boolean', () => {
    // FQL: "stringValue"
    matcher.ir = '"stringValue"'

    simpleEvent.stringValue = 'true'
    expect(matches(simpleEvent, matcher)).toBe(false)
  })
})

describe('boolean literals', () => {
  test('handles true literals', () => {
    // FQL: true
    matcher.ir = `{"value":true}`
    expect(matches({}, matcher)).toBe(true)
  })

  test('handles false literals', () => {
    // FQL: false
    matcher.ir = `{"value":false}`
    expect(matches({}, matcher)).toBe(false)
  })
})

describe('functions', () => {
  test('match() works', () => {
    // FQL: match("test@test.com", "*.com")
    matcher.ir = `["match", {"value": "test@test.com"}, {"value": "*.com"}]`
    expect(matches(simpleEvent, matcher)).toBe(true)

    for (const matcherTest of matcherTests) {
      const pattern = matcherTest[0]
      const str = matcherTest[1]
      const expectedResult = matcherTest[2]

      matcher.ir = `["match", {"value": "${str}"}, {"value": "${pattern}"}]`
      expect(matches({}, matcher)).toBe(expectedResult)
    }
  })

  test('contains() works', () => {
    // FQL: contains(email, ".com")
    matcher.ir = `["contains", "email", {"value": ".com"}]`
    simpleEvent.email = 'test@test.com'
    expect(matches(simpleEvent, matcher)).toBe(true)

    simpleEvent.email = 'test@test.org'
    expect(matches(simpleEvent, matcher)).toBe(false)
  })

  test('lowercase() works', () => {
    // FQL: "test" = lowercase("TEST")
    matcher.ir = `["=", {"value": "test"}, ["lowercase", {"value": "TEST"}]]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: "TEST" = lowercase("TEST")
    matcher.ir = `["=", {"value": "TEST"}, ["lowercase", {"value": "TEST"}]]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('length() works', () => {
    // FQL: 4 = length("TEST")
    matcher.ir = `["=", {"value": 4}, ["length", {"value": "TEST"}]]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 5 = length("TEST")
    matcher.ir = `["=", {"value": 5}, ["length", {"value": "TEST"}]]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('typeof() works', () => {
    // FQL: "boolean" = typeof(true)
    matcher.ir = `["=", {"value": "boolean"}, ["typeof", {"value": true}]]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: "boolean" = typeof("str")
    matcher.ir = `["=", {"value": "boolean"}, ["typeof", {"value": "str"}]]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('unknown functions fail', () => {
    // FQL: <Not valid FQL>
    matcher.ir = `["findTheDefiniteIntegralOf", {"value": "2x+47"}, {"value": "Bounded from 1 to 3"}]`
    expect(() => {
      matches({}, matcher)
    }).toThrow()
  })
})

describe('arrays', () => {
  test('arrays with same contents and order are equal', () => {
    // FQL: [] = []
    matcher.ir = `["=",{"value":[]},{"value":[]}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: [1] = [1]
    matcher.ir = `["=",{"value":[{"value":1}]},{"value":[{"value":1}]}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: [1, 2] = [1, 2]
    matcher.ir = `["=",{"value":[{"value":1}, {"value":2}]},{"value":[{"value":1}, {"value":2}]}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: [1, 2] = [2, 1]
    matcher.ir = `["=",{"value":[{"value":1}, {"value":2}]},{"value":[{"value":2}, {"value":1}]}]`
    expect(matches({}, matcher)).toBe(false)
  })
})

describe('number comparison operands', () => {
  test('= works', () => {
    // FQL: 0 = 0
    matcher.ir = `["=",{"value":0},{"value":0}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 0 = 1
    matcher.ir = `["=",{"value":0},{"value":1}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('!= works', () => {
    // FQL: 5 != 6
    matcher.ir = `["!=",{"value":5},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 7 != 7
    matcher.ir = `["!=",{"value":7},{"value":7}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('<= works', () => {
    // FQL: 5 <= 6
    matcher.ir = `["<=",{"value":5},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 6 <= 6
    matcher.ir = `["<=",{"value":6},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 7 <= 6
    matcher.ir = `["<=",{"value":7},{"value":6}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('>= works', () => {
    // FQL: 5 >= 6
    matcher.ir = `[">=",{"value":5},{"value":6}]`
    expect(matches({}, matcher)).toBe(false)

    // FQL: 6 >= 6
    matcher.ir = `[">=",{"value":6},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 7 >= 6
    matcher.ir = `[">=",{"value":7},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)
  })

  test('< works', () => {
    // FQL: 5 < 6
    matcher.ir = `["<",{"value":5},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: 6 < 6
    matcher.ir = `["<",{"value":6},{"value":6}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('> works', () => {
    // FQL: 6 > 6
    matcher.ir = `[">",{"value":6},{"value":6}]`
    expect(matches({}, matcher)).toBe(false)

    // FQL: 7 > 6
    matcher.ir = `[">",{"value":7},{"value":6}]`
    expect(matches({}, matcher)).toBe(true)
  })
})

describe('binary operands', () => {
  test('and works', () => {
    // FQL: true and true and true
    matcher.ir = `["and",{"value":true},{"value":true},{"value":true}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: true and true and false
    matcher.ir = `["and",{"value":true},{"value":true},{"value":false}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('or works', () => {
    // FQL: false or false or true
    matcher.ir = `["or",{"value":false},{"value":false},{"value":true}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: false or false or false
    matcher.ir = `["or",{"value":false},{"value":false},{"value":false}]`
    expect(matches({}, matcher)).toBe(false)
  })

  test('in() works', () => {
    // FQL: "event" in ["event", "str"]
    matcher.ir = `["in", {"value": "event"}, {"value": [{"value": "event"}, {"value": "str"}]}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: "str" in ["event", "str"]
    matcher.ir = `["in", {"value": "str"}, {"value": [{"value": "event"}, {"value": "str"}]}]`
    expect(matches({}, matcher)).toBe(true)

    // FQL: "blah" in ["event", "str"]
    matcher.ir = `["in", {"value": "blah"}, {"value": [{"value": "event"}, {"value": "str"}]}]`
    expect(matches({}, matcher)).toBe(false)

    // FQL: event in ["Clicked", "Viewed"]
    matcher.ir = `["in", "event", {"value": [{"value": "Clicked"}, {"value": "Viewed"}]}]`
    simpleEvent.event = 'Clicked'
    expect(matches(simpleEvent, matcher)).toBe(true)

    matcher.ir = `["in", "event", {"value": [{"value": "Clicked"}, {"value": "Viewed"}]}]`
    simpleEvent.event = 'Blah'
    expect(matches(simpleEvent, matcher)).toBe(false)

    matcher.ir = `["in", {"value": 10}, {"value": [{"value": "Clicked"}, {"value": 10}]}]`
    simpleEvent.event = 'Blah'
    expect(matches(simpleEvent, matcher)).toBe(true)

    matcher.ir = `["in", {"value": "track"}, {"value": ["event", "type"]}]`
    simpleEvent.event = 'Blah'
    expect(matches(simpleEvent, matcher)).toBe(true)

    matcher.ir = `["in", {"value": "track"}, {"value": []}]`
    expect(matches(simpleEvent, matcher)).toBe(false)

    matcher.ir = `["in", {"value": null}, {"value": [{"value": "Clicked"}, {"value": 10}]}]`
    simpleEvent.event = 'Blah'
    expect(matches(simpleEvent, matcher)).toBe(false)
  })
})

describe('subexpressions', () => {
  test('nested and/ors work', () => {
    // FQL: (false or true) and true
    matcher.ir = `["and",["or",{"value":false},{"value":true}],{"value":true}]`
    expect(matches({}, matcher)).toBe(true)
  })
})

const matcherTests = [
  ['abc', 'abc', true],
  ['*', 'abc', true],
  ['*c', 'abc', true],
  ['*b', 'abc', false],
  ['a*', 'a', true],
  ['a*', 'abc', true],
  ['a*', 'ab/c', true],
  ['a*/b', 'abc/b', true],
  ['a*/b', 'a/c/b', true],
  ['a*b*c*d*e*/f', 'axbxcxdxe/f', true],
  ['a*b*c*d*e*/f', 'axbxcxdxexxx/f', true],
  ['a*b*c*d*e*/f', 'axbxcxdxe/xxx/f', true],
  ['a*b*c*d*e*/f', 'axbxcxdxexxx/fff', false],
  ['a*b?c*x', 'abxbbxdbxebxczzx', true],
  ['a*b?c*x', 'abxbbxdbxebxczzy', false],
  ['*a*b*c*', 'abcabcabc', true],
  ['ab[c]', 'abc', true],
  ['ab[b-d]', 'abc', true],
  ['ab[e-g]', 'abc', false],
  ['ab[^c]', 'abc', false],
  ['ab[^b-d]', 'abc', false],
  ['ab[^e-g]', 'abc', true],
  ['a\\\\*b', 'a*b', true],
  ['a\\\\ b', 'a b', true],
  ['a\\\\*b', 'ab', false],
  ['a?b', 'a☺b', true],
  ['a[^a]b', 'a☺b', true],
  ['a???b', 'a☺b', false],
  ['a[^a][^a][^a]b', 'a☺b', false],
  ['[a-ζ]*', 'α', true],
  ['*[a-ζ]', 'A', false],
  ['a?b', 'a/b', true],
  ['a*b', 'a/b', true],
  ['[\\\\]a]', ']', true],
  ['[\\\\-]', '-', true],
  ['[x\\\\-]', 'x', true],
  ['[x\\\\-]', '-', true],
  ['[x\\\\-]', 'z', false],
  ['[\\\\-x]', 'x', true],
  ['[\\\\-x]', '-', true],
  ['[\\\\-x]', 'a', false],
  ['[]a]', ']', false],
  ['[-]', '-', false],
  ['[x-]', 'x', false],
  ['[x-]', '-', false],
  ['[x-]', 'z', false],
  ['[-x]', 'x', false],
  ['[-x]', '-', false],
  ['[-x]', 'a', false],
  ['\\\\', 'a', false],
  ['[a-b-c]', 'a', false],
  ['[', 'a', false],
  ['[^', 'a', false],
  ['[^bc', 'a', false],
  ['a[', 'a', false],
  ['a[', 'ab', false],
  ['*x', 'xxx', true],
]
