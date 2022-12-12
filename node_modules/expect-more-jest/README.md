# expect-more-jest

> Write Beautiful Specs with Custom Matchers for Jest

[![NPM version](http://img.shields.io/npm/v/expect-more-jest.svg?style=flat-square)](https://www.npmjs.com/package/expect-more-jest)
[![NPM downloads](http://img.shields.io/npm/dm/expect-more-jest.svg?style=flat-square)](https://www.npmjs.com/package/expect-more-jest)
[![Build Status](http://img.shields.io/travis/JamieMason/expect-more/master.svg?style=flat-square)](https://travis-ci.org/JamieMason/expect-more)
[![Maintainability](https://api.codeclimate.com/v1/badges/9f4abbef97ae0d23d97e/maintainability)](https://codeclimate.com/github/JamieMason/expect-more/maintainability)
[![Gitter Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/JamieMason/expect-more)
[![Donate via PayPal](https://img.shields.io/badge/donate-paypal-blue.svg)](https://www.paypal.me/foldleft)
[![Backers](https://opencollective.com/fold_left/backers/badge.svg)](https://opencollective.com/fold_left#backer)
[![Sponsors](https://opencollective.com/fold_left/sponsors/badge.svg)](https://opencollective.com/fold_left#sponsors)
[![Analytics](https://ga-beacon.appspot.com/UA-45466560-5/expect-more-jest?flat&useReferer)](https://github.com/igrigorik/ga-beacon)
[![Follow JamieMason on GitHub](https://img.shields.io/github/followers/JamieMason.svg?style=social&label=Follow)](https://github.com/JamieMason)
[![Follow fold_left on Twitter](https://img.shields.io/twitter/follow/fold_left.svg?style=social&label=Follow)](https://twitter.com/fold_left)

expect-more-jest is a huge library of test matchers for a range of common use-cases, to make tests easier to read and
produce relevant and useful messages when they fail. Avoid vague messages such as _"expected false to be true"_ in
favour of useful cues like _"expected 3 to be even number"_, and avoid implementation noise such as
`expect(paws.length % 2 === 0).toEqual(true)` in favour of simply stating that you
`expect(paws.length).toBeEvenNumber()`.

## Installation

```
npm install expect-more-jest --save-dev
```

## Configuration

The simplest way to integrate is to set the [`setupFilesAfterEnv`][setup-files-after-env] array of Jest's
[jest.config.js][jest-config] to include `require.resolve('expect-more-jest')`.

Note: If your Editor does not recognise that you are using custom matchers, add a `global.d.ts` file at the root of your
project containing:

```ts
import 'expect-more-jest';
```

## Matchers

```ts
expect(value).toBeAfter(other: Date);
expect(value).toBeArray();
expect(value).toBeArrayOfBooleans();
expect(value).toBeArrayOfNumbers();
expect(value).toBeArrayOfObjects();
expect(value).toBeArrayOfSize(size: number);
expect(value).toBeArrayOfStrings();
expect(value).toBeBefore(other: Date);
expect(value).toBeBoolean();
expect(value).toBeCalculable();
expect(value).toBeDate();
expect(value).toBeDivisibleBy(ber, divisor: any);
expect(value).toBeEmptyArray();
expect(value).toBeEmptyObject();
expect(value).toBeEmptyString();
expect(value).toBeEvenNumber();
expect(value).toBeFalse();
expect(value).toBeFunction();
expect(value).toBeIso8601();
expect(value).toBeJsonString();
expect(value).toBeLongerThan(other: string);
expect(value).toBeNonEmptyArray();
expect(value).toBeNonEmptyObject();
expect(value).toBeNonEmptyString();
expect(value).toBeNumber();
expect(value).toBeObject();
expect(value).toBeOddNumber();
expect(value).toBeRegExp();
expect(value).toBeSameLengthAs(other: string);
expect(value).toBeShorterThan(other: string);
expect(value).toBeString();
expect(value).toBeTrue();
expect(value).toBeValidDate();
expect(value).toBeWhitespace();
expect(value).toBeWholeNumber();
expect(value).toBeWithinRange(floor: number, ceiling: number);
expect(value).toEndWith(other: string);
expect(value).toHandleMissingBranches();
expect(value).toHandleMissingLeaves();
expect(value).toHandleMissingNodes();
expect(value).toHandleNullBranches();
expect(value).toHandleNullLeaves();
expect(value).toHandleNullNodes();
expect(value).toHaveArray(propPath: string);
expect(value).toHaveArrayOfBooleans(propPath: string);
expect(value).toHaveArrayOfNumbers(propPath: string);
expect(value).toHaveArrayOfObjects(propPath: string);
expect(value).toHaveArrayOfSize(propPath: string, size: number);
expect(value).toHaveArrayOfStrings(propPath: string);
expect(value).toHaveBoolean(propPath: string);
expect(value).toHaveCalculable(propPath: string);
expect(value).toHaveDate(propPath: string);
expect(value).toHaveDateAfter(propPath: string, otherDate: Date);
expect(value).toHaveDateBefore(propPath: string, otherDate: Date);
expect(value).toHaveEmptyArray(propPath: string);
expect(value).toHaveEmptyObject(propPath: string);
expect(value).toHaveEmptyString(propPath: string);
expect(value).toHaveEvenNumber(propPath: string);
expect(value).toHaveFalse(propPath: string);
expect(value).toHaveIso8601(propPath: string);
expect(value).toHaveJsonString(propPath: string);
expect(value).toHaveLongerThan(propPath: string, other: string | any[]);
expect(value).toHaveMethod(propPath: string);
expect(value).toHaveNonEmptyArray(propPath: string);
expect(value).toHaveNonEmptyObject(propPath: string);
expect(value).toHaveNonEmptyString(propPath: string);
expect(value).toHaveNumber(propPath: string);
expect(value).toHaveNumberWithinRange(propPath: string, floor: number, ceiling: number);
expect(value).toHaveObject(propPath: string);
expect(value).toHaveOddNumber(propPath: string);
expect(value).toHaveSameLengthAs(propPath: string, other: string | any[]);
expect(value).toHaveShorterThan(propPath: string, other: string | any[]);
expect(value).toHaveString(propPath: string);
expect(value).toHaveTrue(propPath: string);
expect(value).toHaveWhitespace(propPath: string);
expect(value).toHaveWholeNumber(propPath: string);
expect(value).toStartWith(other: string);
```

<!-- Links -->

[jest-config]: https://jestjs.io/docs/en/configuration
[jest]: https://jestjs.io
[setup-files-after-env]: https://jestjs.io/docs/en/configuration#setupfilesafterenv-array
