import rules from '@/libs/rules'
import FileUpload from '../../src/FileUpload'


/**
 * Accepted rule
 */
describe('accepted', () => {
  it('passes with true', async () => expect(await rules.accepted({ value: 'yes' })).toBe(true))

  it('passes with on', async () => expect(await rules.accepted({ value: 'on' })).toBe(true))

  it('passes with 1', async () => expect(await rules.accepted({ value: '1' })).toBe(true))

  it('passes with number 1', async () => expect(await rules.accepted({ value: 1 })).toBe(true))

  it('passes with boolean true', async () => expect(await rules.accepted({ value: true })).toBe(true))

  it('fail with boolean false', async () => expect(await rules.accepted({ value: false })).toBe(false))

  it('fail with "false"', async () => expect(await rules.accepted({ value: 'false' })).toBe(false))
})

/**
 * Checks if a date is after another date
 */
describe('after', () => {
  const today = new Date()
  const tomorrow = new Date()
  const yesterday = new Date()
  tomorrow.setDate(today.getDate() + 1)
  yesterday.setDate(today.getDate() - 1)

  it('passes with tomorrow’s date object', async () => expect(await rules.after({ value: tomorrow })).toBe(true))

  it('passes with future date', async () => expect(await rules.after({ value: 'January 15, 2999' })).toBe(true))

  it('passes with long past date', async () => expect(await rules.after({ value: yesterday }, 'Jan 15, 2000')).toBe(true))

  it('fails with yesterday’s date', async () => expect(await rules.after({ value: yesterday })).toBe(false))

  it('fails with old date string', async () => expect(await rules.after({ value: 'January, 2000' })).toBe(false))

  it('fails with invalid value', async () => expect(await rules.after({ value: '' })).toBe(false))
})

/**
 * Checks if a date is after another date
 */
describe('alpha', () => {
  it('passes with simple string', async () => expect(await rules.alpha({ value: 'abc' })).toBe(true))

  it('passes with long string', async () => expect(await rules.alpha({ value: 'lkashdflaosuihdfaisudgflakjsdbflasidufg' })).toBe(true))

  it('passes with single character', async () => expect(await rules.alpha({ value: 'z' })).toBe(true))

  it('passes with accented character', async () => expect(await rules.alpha({ value: 'jüstin' })).toBe(true))

  it('passes with polish diacritic character', async () => expect(await rules.alpha({ value: 'bęlch' })).toBe(true))

  it('passes with lots of accented characters', async () => expect(await rules.alpha({ value: 'àáâäïíôöÆ' })).toBe(true))

  it('passes with lots of accented characters if invalid set', async () => expect(await rules.alpha({ value: 'àáâäïíôöÆ' }, 'russian')).toBe(true))

  it('fails with lots of accented characters if latin', async () => expect(await rules.alpha({ value: 'àáâäïíôöÆ' }, 'latin')).toBe(false))

  it('fails with numbers', async () => expect(await rules.alpha({ value: 'justin83' })).toBe(false))

  it('fails with symbols', async () => expect(await rules.alpha({ value: '-justin' })).toBe(false))
})

/**
 * Checks if a date alpha and numeric
 */
describe('alphanumeric', () => {
  it('passes with simple string', async () => expect(await rules.alphanumeric({ value: '567abc' })).toBe(true))

  it('passes with long string', async () => expect(await rules.alphanumeric({ value: 'lkashdfla234osuihdfaisudgflakjsdbfla567sidufg' })).toBe(true))

  it('passes with single character', async () => expect(await rules.alphanumeric({ value: 'z' })).toBe(true))

  it('passes with accented character', async () => expect(await rules.alphanumeric({ value: 'jüst56in' })).toBe(true))

  it('passes with polish diacritic character', async () => expect(await rules.alphanumeric({ value: 'jźąż' })).toBe(true))

  it('passes with lots of accented characters', async () => expect(await rules.alphanumeric({ value: 'àáâ7567567äïíôöÆ' })).toBe(true))

  it('passes with lots of accented characters if invalid set', async () => expect(await rules.alphanumeric({ value: '123123àáâäï67íôöÆ' }, 'russian')).toBe(true))

  it('fails with lots of accented characters if latin', async () => expect(await rules.alphanumeric({ value: 'àáâäï123123íôöÆ' }, 'latin')).toBe(false))

  it('fails with decimals in', async () => expect(await rules.alphanumeric({ value: 'abcABC99.123' })).toBe(false))
})

/**
 * Checks if a date is after another date
 */
describe('before', () => {
  const today = new Date()
  const tomorrow = new Date()
  const yesterday = new Date()
  tomorrow.setDate(today.getDate() + 1)
  yesterday.setDate(today.getDate() - 1)

  it('fails with tomorrow’s date object', async () => expect(await rules.before({ value: tomorrow })).toBe(false))

  it('fails with future date', async () => expect(await rules.before({ value: 'January 15, 2999' })).toBe(false))

  it('fails with long past date', async () => expect(await rules.before({ value: yesterday }, 'Jan 15, 2000')).toBe(false))

  it('passes with yesterday’s date', async () => expect(await rules.before({ value: yesterday })).toBe(true))

  it('passes with old date string', async () => expect(await rules.before({ value: 'January, 2000' })).toBe(true))

  it('fails with invalid value', async () => expect(await rules.after({ value: '' })).toBe(false))
})

/**
 * Checks if between
 */
describe('between', () => {
  it('passes with simple number', async () => expect(await rules.between({ value: 5 }, 0, 10)).toBe(true))

  it('passes with simple number string', async () => expect(await rules.between({ value: '5' }, '0', '10')).toBe(true))

  it('passes with decimal number string', async () => expect(await rules.between({ value: '0.5' }, '0', '1')).toBe(true))

  it('passes with string length', async () => expect(await rules.between({ value: 'abc' }, 2, 4)).toBe(true))

  it('fails with string length too long', async () => expect(await rules.between({ value: 'abcdef' }, 2, 4)).toBe(false))

  it('fails with string length too short', async () => expect(await rules.between({ value: 'abc' }, 3, 10)).toBe(false))

  it('fails with number to small', async () => expect(await rules.between({ value: 0 }, 3, 10)).toBe(false))

  it('fails with number to large', async () => expect(await rules.between({ value: 15 }, 3, 10)).toBe(false))

  it('passes when forced to value', async () => expect(await rules.between({ value: '4' }, 3, 10, 'value')).toBe(true))

  it('fails when forced to value', async () => expect(await rules.between({ value: 442 }, 3, 10, 'value')).toBe(false))

  it('passes when forced to length', async () => expect(await rules.between({ value: 7442 }, 3, 10, 'length')).toBe(true))

  it('fails when forced to length', async () => expect(await rules.between({ value: 6 }, 3, 10, 'length')).toBe(false))
})

/**
 * Confirm
 */
describe('confirm', () => {
  it('passes when the values are the same strings', async () => expect(await rules.confirm(
    { value: 'abc', name: 'password', getGroupValues: () => ({ password_confirm: 'abc' }) }
  )).toBe(true))

  it('passes when the values are the same integers', async () => expect(await rules.confirm(
    { value: 4422132, name: 'xyz', getGroupValues: () => ({ xyz_confirm: 4422132 }) }
  )).toBe(true))

  it('passes when using a custom field', async () => expect(await rules.confirm(
    { value: 4422132, name: 'name', getGroupValues: () => ({ other_field: 4422132 }) },
    'other_field'
  )).toBe(true))

  it('passes when using a field ends in _confirm', async () => expect(await rules.confirm(
    { value: '$ecret', name: 'password_confirm', getGroupValues: () => ({ password: '$ecret' }) }
  )).toBe(true))

  it('fails when using different strings', async () => expect(await rules.confirm(
    { value: 'Justin', name: 'name', getGroupValues: () => ({ name_confirm: 'Daniel' }) },
  )).toBe(false))

  it('fails when the types are different', async () => expect(await rules.confirm(
    { value: '1234', name: 'num', getGroupValues: () => ({ num_confirm: 1234 }) },
  )).toBe(false))
})

/**
 * Determines if the string is a date
 */
describe('date', () => {
  it('passes with month day year', async () => expect(await rules.date({ value: 'December 17, 2020' })).toBe(true))

  it('passes with month day', async () => expect(await rules.date({ value: 'December 17' })).toBe(true))

  it('passes with short month day', async () => expect(await rules.date({ value: 'Dec 17' })).toBe(true))

  it('passes with short month day', async () => expect(await rules.date({ value: 'Dec 17 12:34:15' })).toBe(true))

  it('passes with out of bounds number', async () => expect(await rules.date({ value: 'January 77' })).toBe(true))

  it('passes with only month', async () => expect(await rules.date({ value: 'January' })).toBe(false))

  it('passes with valid date format', async () => expect(await rules.date({ value: '12/10/1987' }, 'MM/DD/YYYY')).toBe(true))

  it('passes with date ending in zero', async () => expect(await rules.date({ value: '12/10/1987' }, 'MM/D/YYYY')).toBe(true))

  it('fails with simple number and date format', async () => expect(await rules.date({ value: '1234' }, 'MM/DD/YYYY')).toBe(false))

  it('fails with only day of week', async () => expect(await rules.date({ value: 'saturday' })).toBe(false))

  it('fails with random string', async () => expect(await rules.date({ value: 'Pepsi 17' })).toBe(false))

  it('fails with random number', async () => expect(await rules.date({ value: '1872301237' })).toBe(false))

})

/**
 * Checks if email.
 *
 * Note: testing is light, regular expression used is here: http://jsfiddle.net/ghvj4gy9/embedded/result,js/
 */
describe('email', () => {
  it('passes normal email', async () => expect(await rules.email({ value: 'dev+123@wearebraid.com' })).toBe(true))

  it('passes numeric email', async () => expect(await rules.email({ value: '12345@google.com' })).toBe(true))

  it('passes unicode email', async () => expect(await rules.email({ value: 'àlphä@❤️.ly' })).toBe(true))

  it('passes numeric with new tld', async () => expect(await rules.email({ value: '12345@google.photography' })).toBe(true))

  it('fails string without tld', async () => expect(await rules.email({ value: '12345@localhost' })).toBe(false))

  it('fails string without invalid name', async () => expect(await rules.email({ value: '1*(123)2345@localhost' })).toBe(false))
})

/**
 * Checks if value ends with a one of the specified Strings.
 */
describe('endsWith', () => {
  it('fails when value ending is not in stack of single value', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, '@gmail.com')).toBe(false)
  })

  it('fails when value ending is not in stack of multiple values', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, '@gmail.com', '@yahoo.com')).toBe(false)
  })

  it('fails when passed value is not a string', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, ['@gmail.com', '@wearebraid.com'])).toBe(false)
  })

  it('fails when passed value is not a string', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, { value: '@wearebraid.com' })).toBe(false)
  })

  it('passes when a string value is present and matched even if non-string values also exist as arguments', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, { value: 'bad data' }, ['no bueno'], '@wearebraid.com')).toBe(true)
  })

  it('passes when stack consists of zero values', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' })).toBe(true)
  })

  it('passes when value ending is in stack of single value', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, '@wearebraid.com')).toBe(true)
  })

  it('passes when value ending is in stack of multiple values', async () => {
    expect(await rules.endsWith({ value: 'andrew@wearebraid.com' }, '@yahoo.com', '@wearebraid.com', '@gmail.com')).toBe(true)
  })
})

/**
 * In rule
 */
describe('in', () => {
  it('fails when not in stack', async () => {
    expect(await rules.in({ value: 'third' }, 'first', 'second')).toBe(false)
  })

  it('fails when case sensitive mismatch is in stack', async () => {
    expect(await rules.in({ value: 'third' }, 'first', 'second', 'Third')).toBe(false)
  })

  it('fails comparing dissimilar objects', async () => {
    expect(await rules.in({ value: { f: 'abc' } }, { a: 'cdf' }, { b: 'abc' })).toBe(false)
  })

  it('passes when case sensitive match is in stack', async () => {
    expect(await rules.in({ value: 'third' }, 'first', 'second', 'third')).toBe(true)
  })

  it('passes a shallow array compare', async () => {
    expect(await rules.in({ value: ['abc'] }, ['cdf'], ['abc'])).toBe(true)
  })

  it('passes a shallow object compare', async () => {
    expect(await rules.in({ value: { f: 'abc' } }, { a: 'cdf' }, { f: 'abc' },)).toBe(true)
  })
})

/**
 * Matches rule
 */
describe('matches', () => {
  it('simple strings fail if they aren’t equal', async () => {
    expect(await rules.matches({ value: 'third' }, 'first')).toBe(false)
  })

  it('fails on non matching regex', async () => {
    expect(await rules.matches({ value: 'third' }, /^thirds/)).toBe(false)
  })

  it('passes if simple strings match', async () => {
    expect(await rules.matches({ value: 'second' }, 'third', 'second')).toBe(true)
  })

  it('passes on matching regex', async () => {
    expect(await rules.matches({ value: 'third' }, /^third/)).toBe(true)
  })

  it('passes on matching mixed regex and string', async () => {
    expect(await rules.matches({ value: 'first-fourth' }, 'second', /^third/, /fourth$/)).toBe(true)
  })

  it('fails on a regular expression encoded as a string', async () => {
    expect(await rules.matches({ value: 'mypassword' }, '/[0-9]/')).toBe(false)
  })

  it('passes on a regular expression encoded as a string', async () => {
    expect(await rules.matches({ value: 'mypa55word' }, '/[0-9]/')).toBe(true)
  })

  it('passes on a regular expression containing slashes', async () => {
    expect(await rules.matches({ value: 'https://' }, '/https?:///')).toBe(true)
  })
})

/**
 * Mime types.
 */
describe('mime', () => {
  it('passes basic image/jpeg stack', async () => {
    const fileUpload = new FileUpload({
      files: [{ type: 'image/jpeg' }]
    })
    expect(await rules.mime({ value: fileUpload }, 'image/png', 'image/jpeg')).toBe(true)
  })

  it('passes when match is at begining of stack', async () => {
    const fileUpload = new FileUpload({
      files: [{ type: 'document/pdf' }]
    })
    expect(await rules.mime({ value: fileUpload }, 'document/pdf')).toBe(true)
  })

  it('fails when not in stack', async () => {
    const fileUpload = new FileUpload({
      files: [{ type: 'application/json' }]
    })
    expect(await rules.mime({ value: fileUpload }, 'image/png', 'image/jpeg')).toBe(false)
  })
})

/**
 * Minimum.
 */
describe('min', () => {
  it('passes when a number string', async () => expect(await rules.min({ value: '5' }, '5')).toBe(true))

  it('passes when a number', async () => expect(await rules.min({ value: 6 }, 5)).toBe(true))

  it('passes when a string length', async () => expect(await rules.min({ value: 'foobar' }, '6')).toBe(true))

  it('passes when a array length', async () => expect(await rules.min({ value: Array(6) }, '6')).toBe(true))

  it('passes when string is forced to value', async () => expect(await rules.min({ value: 'bcd' }, 'aaa', 'value')).toBe(true))

  it('fails when string is forced to lesser value', async () => expect(await rules.min({ value: 'a' }, 'b', 'value')).toBe(false))

  it('passes when a number is forced to length', async () => expect(await rules.min({ value: '000' }, 3, 'length')).toBe(true))

  it('fails when a number is forced to length', async () => expect(await rules.min({ value: '44' }, 3, 'length')).toBe(false))

  it('fails when a array length', async () => expect(await rules.min({ value: Array(6) }, '7')).toBe(false))

  it('fails when a string length', async () => expect(await rules.min({ value: 'bar' }, 4)).toBe(false))

  it('fails when a number', async () => expect(await rules.min({ value: 3 }, '7')).toBe(false))

})

/**
 * Maximum.
 */
describe('max', () => {
  it('passes when a number string', async () => expect(await rules.max({ value: '5' }, '5')).toBe(true))

  it('passes when a number', async () => expect(await rules.max({ value: 5 }, 6)).toBe(true))

  it('passes when a string length', async () => expect(await rules.max({ value: 'foobar' }, '6')).toBe(true))

  it('passes when a array length', async () => expect(await rules.max({ value: Array(6) }, '6')).toBe(true))

  it('passes when forced to validate on length', async () => expect(await rules.max({ value: 10 }, 3, 'length')).toBe(true))

  it('passes when forced to validate string on value', async () => expect(await rules.max({ value: 'b' }, 'e', 'value')).toBe(true))

  it('fails when a array length', async () => expect(await rules.max({ value: Array(6) }, '5')).toBe(false))

  it('fails when a string length', async () => expect(await rules.max({ value: 'bar' }, 2)).toBe(false))

  it('fails when a number', async () => expect(await rules.max({ value: 10 }, '7')).toBe(false))

  it('fails when a number', async () => expect(await rules.max({ value: 10 }, '7')).toBe(false))

  it('fails when forced to validate on length', async () => expect(await rules.max({ value: -10 }, '1', 'length')).toBe(false))
})

/**
 * Maximum.
 */
describe('not', () => {
  it('passes when a number string', async () => expect(await rules.not({ value: '5' }, '6')).toBe(true))

  it('passes when a number', async () => expect(await rules.not({ value: 1 }, 30)).toBe(true))

  it('passes when a string', async () => expect(await rules.not({ value: 'abc' }, 'def')).toBe(true))

  it('fails when a shallow equal array', async () => expect(await rules.not({ value: ['abc'] }, ['abc'])).toBe(false))

  it('fails when a shallow equal object', async () => expect(await rules.not({ value: { a: 'abc' } }, ['123'], { a: 'abc' })).toBe(false))

  it('fails when string is in stack', async () => expect(await rules.not({ value: 'a' }, 'b', 'c', 'd', 'a', 'f')).toBe(false))
})

/**
 * Checks if a date is after another date
 */
describe('number', () => {
  it('passes with simple number string', async () => expect(await rules.number({ value: '123' })).toBe(true))

  it('passes with simple number', async () => expect(await rules.number({ value: 19832461234 })).toBe(true))

  it('passes with float', async () => expect(await rules.number({ value: 198.32464 })).toBe(true))

  it('passes with decimal in string', async () => expect(await rules.number({ value: '567.23' })).toBe(true))

  it('fails with comma in number string', async () => expect(await rules.number({ value: '123,456' })).toBe(false))

  it('fails with alpha', async () => expect(await rules.number({ value: '123sdf' })).toBe(false))
})


/**
 * Required rule
 */
describe('required', () => {
  it('fails on empty string', async () => expect(await rules.required({ value: '' })).toBe(false))

  it('fails with only whitespace as value when second argument is "trim"', async () => expect(await rules.required({ value: ' ' }, 'trim')).toBe(false))
  
  it('fails on empty array', async () => expect(await rules.required({ value: [] })).toBe(false))

  it('fails on empty object', async () => expect(await rules.required({ value: {} })).toBe(false))

  it('fails on null', async () => expect(await rules.required({ value: null })).toBe(false))

  it('passes with only whitespace as value', async () => expect(await rules.required({ value: ' ' })).toBe(true))

  it('passes with only whitespace as value when second argument is not "trim"', async () => expect(await rules.required({ value: ' ' }, 'pre')).toBe(true))

  it('passes with the number zero', async () => expect(await rules.required({ value: 0 })).toBe(true))

  it('passes with the boolean false', async () => expect(await rules.required({ value: false })).toBe(true))

  it('passes with a non empty array', async () => expect(await rules.required({ value: ['123'] })).toBe(true))

  it('passes with a non empty object', async () => expect(await rules.required({ value: { a: 'b' } })).toBe(true))

  it('passes with FileUpload', async () => expect(await rules.required({ value: new FileUpload({ files: [{ name: 'j.png' }] }) })).toBe(true))

  it('fails with empty FileUpload', async () => expect(await rules.required({ value: new FileUpload({ files: [] }) })).toBe(false))
})

/**
 * Checks if value starts with a one of the specified Strings.
 */
describe('startsWith', () => {
  it('fails when value starting is not in stack of single value', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, 'pizza')).toBe(false)
  })

  it('fails when value starting is not in stack of multiple values', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, 'pizza', 'coffee')).toBe(false)
  })

  it('fails when passed value is not a string', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, ['taco', 'pizza'])).toBe(false)
  })

  it('fails when passed value is not a string', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, { value: 'taco' })).toBe(false)
  })

  it('passes when a string value is present and matched even if non-string values also exist as arguments', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, { value: 'taco' }, ['taco'], 'taco')).toBe(true)
  })

  it('passes when stack consists of zero values', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' })).toBe(true)
  })

  it('passes when value starting is in stack of single value', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, 'taco')).toBe(true)
  })

  it('passes when value starting is in stack of multiple values', async () => {
    expect(await rules.startsWith({ value: 'taco tuesday' }, 'pizza', 'taco', 'coffee')).toBe(true)
  })
})

/**
 * Url rule.
 *
 * Note: these are just sanity checks because the actual package we use is
 * well tested: https://github.com/segmentio/is-url/blob/master/test/index.js
 */
describe('url', () => {
  it('passes with http://google.com', async () => expect(await rules.url({ value: 'http://google.com' })).toBe(true))

  it('fails with google.com', async () => expect(await rules.url({ value: 'google.com' })).toBe(false))
})
