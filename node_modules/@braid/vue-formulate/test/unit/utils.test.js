import { parseRules, parseLocale, regexForFormat, cloneDeep, isValueType, camel, groupBails, isEmpty } from '@/libs/utils'
import rules from '@/libs/rules'
import FileUpload from '@/FileUpload';
import { equals } from '../../src/libs/utils';

describe('parseRules', () => {
  it('parses single string rules, returning empty arguments array', () => {
    expect(parseRules('required', rules)).toEqual([
      [rules.required, [], 'required', null]
    ])
  })

  it('throws errors for invalid validation rules', () => {
    expect(() => {
      parseRules('required|notarule', rules, null)
    }).toThrow()
  })

  it('parses arguments for a rule', () => {
    expect(parseRules('in:foo,bar', rules)).toEqual([
      [rules.in, ['foo', 'bar'], 'in', null]
    ])
  })

  it('parses multiple string rules and arguments', () => {
    expect(parseRules('required|in:foo,bar', rules)).toEqual([
      [rules.required, [], 'required', null],
      [rules.in, ['foo', 'bar'], 'in', null]
    ])
  })

  it('parses multiple array rules and arguments', () => {
    expect(parseRules(['required', 'in:foo,bar'], rules)).toEqual([
      [rules.required, [], 'required', null],
      [rules.in, ['foo', 'bar'], 'in', null]
    ])
  })

  it('parses array rules with expression arguments', () => {
    expect(parseRules([
      ['matches', /^abc/, '1234']
    ], rules)).toEqual([
      [rules.matches, [/^abc/, '1234'], 'matches', null]
    ])
  })

  it('parses string rules with caret modifier', () => {
    expect(parseRules('^required|min:10', rules)).toEqual([
      [rules.required, [], 'required', '^'],
      [rules.min, ['10'], 'min', null],
    ])
  })

  it('parses array rule with caret modifier', () => {
    expect(parseRules([['required'], ['^max', '10']], rules)).toEqual([
      [rules.required, [], 'required', null],
      [rules.max, ['10'], 'max', '^'],
    ])
  })

  it('ignores empty string rules', () => {
    expect(parseRules('', rules)).toEqual([])
  })

  it('ignores empty string rules', () => {
    expect(parseRules('', rules)).toEqual([])
  })
})


describe('regexForFormat', () => {
  it('allows MM format with other characters', () => expect(regexForFormat('abc/MM').test('abc/01')).toBe(true))

  it('fails MM format with single digit', () => expect(regexForFormat('abc/MM').test('abc/1')).toBe(false))

  it('allows M format with single digit', () => expect(regexForFormat('M/abc').test('1/abc')).toBe(true))

  it('fails MM format when out of range', () => expect(regexForFormat('M/abc').test('13/abc')).toBe(false))

  it('fails M format when out of range', () => expect(regexForFormat('M/abc').test('55/abc')).toBe(false))

  it('Replaces double digits before singles', () => expect(regexForFormat('MMM').test('313131')).toBe(false))

  it('allows DD format with zero digit', () => expect(regexForFormat('xyz/DD').test('xyz/01')).toBe(true))

  it('fails DD format with single digit', () => expect(regexForFormat('xyz/DD').test('xyz/9')).toBe(false))

  it('allows D format with single digit', () => expect(regexForFormat('xyz/D').test('xyz/9')).toBe(true))

  it('fails D format with out of range digit', () => expect(regexForFormat('xyz/D').test('xyz/92')).toBe(false))

  it('fails DD format with out of range digit', () => expect(regexForFormat('xyz/D').test('xyz/32')).toBe(false))

  it('allows YY format with double zeros', () => expect(regexForFormat('YY').test('00')).toBe(true))

  it('fails YY format with four zeros', () => expect(regexForFormat('YY').test('0000')).toBe(false))

  it('allows YYYY format with four zeros', () => expect(regexForFormat('YYYY').test('0000')).toBe(true))

  it('allows MD-YY', () => expect(regexForFormat('MD-YY').test('12-00')).toBe(true))

  it('allows DM-YY', () => expect(regexForFormat('DM-YY').test('12-00')).toBe(true))

  it('allows date like MM/DD/YYYY', () => expect(regexForFormat('MM/DD/YYYY').test('12/18/1987')).toBe(true))

  it('allows date like YYYY-MM-DD', () => expect(regexForFormat('YYYY-MM-DD').test('1987-01-31')).toBe(true))

  it('fails date like YYYY-MM-DD with out of bounds day', () => expect(regexForFormat('YYYY-MM-DD').test('1987-01-32')).toBe(false))
})

describe('isValueType', () => {
  it('passes on strings', () => expect(isValueType('hello')).toBe(true))

  it('passes on numbers', () => expect(isValueType(123)).toBe(true))

  it('passes on booleans', () => expect(isValueType(false)).toBe(true))

  it('passes on symbols', () => expect(isValueType(Symbol(123))).toBe(true))

  it('passes on null', () => expect(isValueType(null)).toBe(true))

  it('passes on undefined', () => expect(isValueType(undefined)).toBe(true))

  it('fails on pojo', () => expect(isValueType({})).toBe(false))

  it('fails on custom type', () => expect(isValueType(FileUpload)).toBe(false))
})

describe('cloneDeep', () => {
  it('basic objects stay the same', () => expect(cloneDeep({ a: 123, b: 'hello' })).toEqual({ a: 123, b: 'hello' }))

  it('basic nested objects stay the same', () => {
    expect(cloneDeep({ a: 123, b: { c: 'hello-world' } }))
    .toEqual({ a: 123, b: { c: 'hello-world' } })
  })

  it('simple pojo reference types are re-created', () => {
    const c = { c: 'hello-world' }
    const clone = cloneDeep({ a: 123, b: c })
    expect(clone.b === c).toBe(false)
  })

  it('retains array structures inside of a pojo', () => {
    const obj = { a: 'abcd', d: ['first', 'second'] }
    const clone = cloneDeep(obj)
    expect(Array.isArray(clone.d)).toBe(true)
  })

  it('removes references inside array structures', () => {
    const deepObj = {foo: 'bar'}
    const obj = { a: 'abcd', d: ['first', deepObj] }
    const clone = cloneDeep(obj)
    expect(clone.d[1] === deepObj).toBe(false)
  })
})

describe('camel', () => {
  it('converts underscore separated words to camelCase', () => {
    expect(camel('this_is_snake_case')).toBe('thisIsSnakeCase')
  })

  it('converts underscore separated words to camelCase even if they start with a number', () => {
    expect(camel('this_is_snake_case_2nd_example')).toBe('thisIsSnakeCase2ndExample')
  })

  it('has no effect on already camelCase words', () => {
    expect(camel('thisIsCamelCase')).toBe('thisIsCamelCase')
  })

  it('does not capitalize the first word or strip first underscore if a phrase starts with an underscore', () => {
    expect(camel('_this_starts_with_an_underscore')).toBe('_thisStartsWithAnUnderscore')
  })

  it('ignores double underscores anywhere in a word', () => {
    expect(camel('__unlikely__thing__')).toBe('__unlikely__thing__')
  })

  it('also converts hyphenated words', () => {
    expect(camel('not-a-good-name')).toBe('notAGoodName')
  })

  it('returns the same function if passed', () => {
    const fn = () => {}
    expect(camel(fn)).toBe(fn)
  })
})


describe('parseLocale', () => {
  it('properly orders the options', () => {
    expect(parseLocale('en-US-VA')).toEqual(['en-US-VA', 'en-US', 'en'])
  })

  it('properly parses a single option', () => {
    expect(parseLocale('en')).toEqual(['en'])
  })
})

describe('groupBails', () => {
  it('wraps non bailed rules in an array', () => {
    const bailGroups = groupBails([[,,'required'], [,,'min']])
    expect(bailGroups).toEqual(
      [ [[,,'required'], [,,'min']] ] // dont bail on either of these
    )
    expect(bailGroups.map(group => !!group.bail)).toEqual([false])
  })

  it('splits bailed rules into two arrays array', () => {
    const bailGroups = groupBails([[,,'required'], [,,'max'], [,, 'bail'], [,, 'matches'], [,,'min']])
    expect(bailGroups).toEqual([
      [ [,,'required'], [,,'max'] ], // dont bail on these
      [ [,, 'matches'] ], // bail on this one
      [ [,,'min'] ] // bail on this one
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([false, true, true])
  })

  it('splits entire rule set when bail is at the beginning', () => {
    const bailGroups = groupBails([[,, 'bail'], [,,'required'], [,,'max'], [,, 'matches'], [,,'min']])
    expect(bailGroups).toEqual([
      [ [,, 'required'] ], // bail on this one
      [ [,, 'max'] ],  // bail on this one
      [ [,, 'matches'] ],  // bail on this one
      [ [,, 'min'] ]  // bail on this one
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([true, true, true, true])
  })

  it('splits no rules when bail is at the end', () => {
    const bailGroups = groupBails([[,,'required'], [,,'max'], [,, 'matches'], [,,'min'], [,, 'bail']])
    expect(bailGroups).toEqual([
      [ [,, 'required'], [,, 'max'], [,, 'matches'], [,, 'min'] ] // dont bail on these
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([false])
  })

  it('splits individual modified names into two groups when at the begining', () => {
    const bailGroups = groupBails([[,,'required', '^'], [,,'max'], [,, 'matches'], [,,'min'] ])
    expect(bailGroups).toEqual([
      [ [,, 'required', '^'] ], // bail on this one
      [ [,, 'max'], [,, 'matches'], [,, 'min'] ] // dont bail on these
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([true, false])
  })

  it('splits individual modified names into three groups when in the middle', () => {
    const bailGroups = groupBails([[,,'required'], [,,'max'], [,, 'matches', '^'], [,,'min'] ])
    expect(bailGroups).toEqual([
      [ [,, 'required'], [,, 'max'] ], // dont bail on these
      [ [,, 'matches', '^'] ], // bail on this one
      [ [,, 'min'] ] // dont bail on this
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([false, true, false])
  })

  it('splits individual modified names into four groups when used twice', () => {
    const bailGroups = groupBails([[,,'required', '^'], [,,'max'], [,, 'matches', '^'], [,,'min'] ])
    expect(bailGroups).toEqual([
      [ [,, 'required', '^'] ], // bail on this
      [ [,, 'max'] ], // dont bail on this
      [ [,, 'matches', '^'] ], // bail on this
      [ [,, 'min'] ] // dont bail on this
    ])
    expect(bailGroups.map(group => !!group.bail)).toEqual([true, false, true, false])
  })

  describe('isEmpty', () => {
    it('is true when undefined', () => expect(isEmpty(undefined)).toBe(true))
    it('is true when empty string', () => expect(isEmpty('')).toBe(true))
    it('is true when null', () => expect(isEmpty(null)).toBe(true))
    it('is true when empty array', () => expect(isEmpty([])).toBe(true))
    it('is true when false', () => expect(isEmpty(false)).toBe(true))
    it('is true when empty pojo', () => expect(isEmpty({})).toBe(true))
    it('is true when empty array with empty pojo', () => expect(isEmpty([{}])).toBe(true))
    it('is true when object has keys but empty values', () => expect(isEmpty({ first: '' })).toBe(true))
    it('is true when object has array of objects with empty values', () => expect(isEmpty([
      { first: '' },
      { second: null },
      { third: false },
      { fourth: [] }
    ])).toBe(true))

    it('is false when string', () => expect(isEmpty('pizza')).toBe(false))
    it('is false when zero string', () => expect(isEmpty('0')).toBe(false))
    it('is false when zero value', () => expect(isEmpty(0)).toBe(false))
    it('is false when has array values', () => expect(isEmpty(['first'])).toBe(false))
    it('is false when has object has values', () => expect(isEmpty([{ key: 'value' }])).toBe(false))
  })

  describe('equals', () => {
    it('is true when simple empty objects', () => expect(equals({}, {})).toBe(true))
    it('is true when same properties and values', () => expect(equals({ a: 'a' }, { a: 'a' })).toBe(true))
    it('is false when same properties and different', () => expect(equals({ a: 'a' }, { a: 'b' })).toBe(false))
    it('is false when different properties and same values', () => expect(equals({ a: 'a' }, { a: 'b' })).toBe(false))
    it('is true when multiple properties and same values of different types', () => expect(equals({ a: 'a', c: 123 }, { a: 'a', c: 123 })).toBe(true))
    it('is true with scalar strings', () => expect(equals('abc', 'abc')).toBe(true))
    it('is true with scalar numbers', () => expect(equals(123, 123)).toBe(true))
    it('is false with different scalar numbers', () => expect(equals(123, 456)).toBe(false))
  })
})
