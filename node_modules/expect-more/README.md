# expect-more

> Curried JavaScript Type Testing Library with Zero Dependencies

[![NPM version](http://img.shields.io/npm/v/expect-more.svg?style=flat-square)](https://www.npmjs.com/package/expect-more)
[![NPM downloads](http://img.shields.io/npm/dm/expect-more.svg?style=flat-square)](https://www.npmjs.com/package/expect-more)
[![Build Status](http://img.shields.io/travis/JamieMason/expect-more/master.svg?style=flat-square)](https://travis-ci.org/JamieMason/expect-more)
[![Maintainability](https://api.codeclimate.com/v1/badges/9f4abbef97ae0d23d97e/maintainability)](https://codeclimate.com/github/JamieMason/expect-more/maintainability)
[![Gitter Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JamieMason/expect-more)
[![Donate via PayPal](https://img.shields.io/badge/donate-paypal-blue.svg)](https://www.paypal.me/foldleft)
[![Backers](https://opencollective.com/fold_left/backers/badge.svg)](https://opencollective.com/fold_left#backer)
[![Sponsors](https://opencollective.com/fold_left/sponsors/badge.svg)](https://opencollective.com/fold_left#sponsors)
[![Analytics](https://ga-beacon.appspot.com/UA-45466560-5/expect-more?flat&useReferer)](https://github.com/igrigorik/ga-beacon)
[![Follow JamieMason on GitHub](https://img.shields.io/github/followers/JamieMason.svg?style=social&label=Follow)](https://github.com/JamieMason)
[![Follow fold_left on Twitter](https://img.shields.io/twitter/follow/fold_left.svg?style=social&label=Follow)](https://twitter.com/fold_left)

## Status

This is a new project which needs a lot of work on documentation. It is under active development so there will likely be
changes, but at its core it is a rewrite of the core logic behind the matchers in
[jasmine-expect](https://github.com/JamieMason/Jasmine-Matchers#readme) which is a mature, well-tested library.

## Installation

```
npm install expect-more --save-dev
```

## Usage

```js
import { endsWith, isWithinRange } from 'expect-more';

endsWith('Script', 'JavaScript');
// => true

const endsWithScript = endsWith('Script');
endsWithScript('JavaScript');
// => true

isWithinRange(10, 20, 21);
// => false

[0, 1, 1, 2, 3, 5, 8, 13, 21, 34].filter(isWithinRange(5, 15));
// => [5, 8, 13]
```

## API

### General

- `isBoolean: (value: any) => boolean`
- `isFalse: (value: any) => boolean`
- `isNull: (value: any) => boolean`
- `isRegExp: (value: any) => boolean`
- `isTrue: (value: any) => boolean`
- `isUndefined: (value: any) => boolean`

### Functions

- `isFunction: (value: any) => boolean`
- `throwsAnyError: (value: () => void) => boolean`
- `throwsErrorOfType: (typeName: string, value: () => void) => boolean`

### Objects

- `hasMember: (memberName: string, value: any) => boolean`
- `isEmptyObject: (value: any) => boolean`
- `isNonEmptyObject: (value: any) => boolean`
- `isObject: (value: any) => boolean`
- `isWalkable: (value: any) => boolean`

### Arrays

- `isArray: (value: any) => boolean`
- `isArrayOfBooleans: (value: any) => boolean`
- `isArrayOfNumbers: (value: any) => boolean`
- `isArrayOfObjects: (value: any) => boolean`
- `isArrayOfSize: (size: number, value: any) => boolean`
- `isArrayOfStrings: (value: any) => boolean`
- `isEmptyArray: (any) => boolean`
- `isNonEmptyArray: (value: any) => boolean`

### Dates

- `isAfter: (other: Date, value: any) => boolean`
- `isBefore: (other: Date, value: any) => boolean`
- `isDate: (value: any) => boolean`
- `isIso8601: (value: any) => boolean`
- `isValidDate: (value: any) => boolean`

### Numbers

- `isCalculable: (value: any) => boolean`
- `isDivisibleBy: (other: number, value: any) => boolean`
- `isEvenNumber: (value: any) => boolean`
- `isGreaterThanOrEqualTo: (other: number, value: any) => boolean`
- `isLessThanOrEqualTo: (other: number, value: any) => boolean`
- `isNear: (other: number, epsilon: number, value: any) => boolean`
- `isNumber: (value: any) => boolean`
- `isOddNumber: (value: any) => boolean`
- `isWholeNumber: (value: any) => boolean`
- `isWithinRange: (floor: number, ceiling: number, value: any) => boolean`

### Strings

- `endsWith: (other: string, value: any) => boolean`
- `isEmptyString: (value: any) => boolean`
- `isJsonString: (value: any) => boolean`
- `isLongerThan: (other: string, value: any) => boolean`
- `isNonEmptyString: (value: any) => boolean`
- `isSameLengthAs: (other: string, value: any) => boolean`
- `isShorterThan: (other: string, value: any) => boolean`
- `isString: (value: any) => boolean`
- `isWhitespace: (value: any) => boolean`
- `startsWith: (other: string, value: any) => boolean`
