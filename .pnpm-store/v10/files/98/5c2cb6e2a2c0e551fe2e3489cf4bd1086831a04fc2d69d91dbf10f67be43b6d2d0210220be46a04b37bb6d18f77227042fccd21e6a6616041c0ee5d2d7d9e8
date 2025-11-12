<!-- (breaking change) `parsePhoneNumberFromString()`: `extract: false` is now the default mode: non-phone-number characters aren't now trimmed on the left and on the right sides of a phone number. For example, `(213) 373-4253` is parsed as a valid phone number, but `Call: (213) 373-4253` is not, because `Call: ` doesn't automatically get trimmed now. For the old behavior, pass `extract: true` option. -->

<!-- Maybe rename `metadata.full.json` -> `metadata.max.json`. -->

<!-- (breaking change) Moved `findPhoneNumbersInText()` to its own subpackage: `libphonenumber-js/find`. The default export is `searchPhoneNumbersInText()` that returns an ES6 "iterator". -->

<!-- Renamed source files: `parsePhoneNumber.js` -> `parsePhoneNumberWithError.js`, etc. -->

<!-- (breaking change) Metadata is often updated, so it has been extracted into its own package: `libphonenumber-metadata`. -->

<!-- `metadata.json` is now included in the package. -->

<!-- (breaking change) `parseNumber()` is now `extended: true` by default (and the `extended` flag is no longer supported) meaning that by default it will parse all even remotely hypothetical phone numbers (this was decided to be the primary use case for this function, and it's how Google's libphonenumber does it). Pass `strict: true` flag for the old "only parse valid numbers" behaviour. -->

<!-- (breaking change) `formatNumber()` no longer supports `formatNumber(numberString, countryString, format)` notation, use `formatNumber({ phone, country }, format)` notation instead. -->

<!-- `type` parameter has been added to `isValidNumber()` for validating phone numbers of a particual type (fixed line, mobile, etc). -->

<!-- (breaking change) Replaced `phone: ...` with `number: ...` in returned objects and arguments in all functions: `formatNumber()`, `parseNumber()`, `isValidNumber()`, `getNumberType()`, `findPhoneNumbers()`. -->

<!-- (breaking change) Removed deprecated `findPhoneNumbers()`, `searchPhoneNumbers()` and `PhoneNumberSearch` functions. Use `findNumbers()`, `searchNumbers()` and `PhoneNumberMatcher` instead. -->

<!-- (breaking change) Better API.

https://github.com/catamphetamine/libphonenumber-js/issues/259

Maybe something like:

const number = parseNumber(value)

const {
  number,
  country,
  nationalNumber,
  carrierCode,
  countryCallingCode,
  valid,
  possible
} = parseNumber(value, { extended: true })

// Maybe rename "extended" to something else.
-->

<!-- (breaking change)
`phone` property of phone number object renamed to `nationalNumber`
-->

<!-- (breaking change) `examples.mobile.json` now provides phone numbers in E.164 format (e.g. `+78005553535`). Previously those numbers were in "national (significant) number" form (e.g. `8005553535`).
-->

<!-- (breaking change) AsYouType -> AsYouTypeFormatter (maybe, or maybe not). -->

<!-- (breaking change) parse.js -> parseNumber.js, format.js -> formatNumber.js, validate.js -> isValidNumber.js. -->

<!-- (breaking change) `findNumbers()` now returns an array of `PhoneNumber` objects instead of objects having shape `{ country, phone }`. -->

<!-- (breaking change) Maybe change metadata from `.json` to `.js` to save size on `,0,` -> `,,`. -->

<!-- (breaking change) Prepend `+` in AsYouType if no `defaultCountry` has been set.

And edit the README:

 * `getNumber()` — Returns the [`PhoneNumber`](#phonenumber). Will return `undefined` if no [national (significant) number](#national-significant-number) has been entered so far, or if no `defaultCountry` has been set and the user enters a phone number not in international format.
-->

<!-- (breaking change) Changed `countries` and `country_calling_codes` properties in metadata: now they're not properties but rather elements of an array (`countries` is an array now rather than an object; `countries` is `metadata[0]` and `country_calling_codes` is `metadata[1]`). If you were using a custom-generated metadata then it has to be re-generated for the new version. -->

This changelog [only](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/16#note_594165443) mentions the changes in the code. See [Google's changelog](https://github.com/google/libphonenumber/blob/master/release_notes.txt) for metadata changes.

1.11.00 / 06.05.2024
====================

* (TypeScript) Fixed Tagged type to be more strict, as suggested in an [issue](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/144) by Islam Sharabash.

1.10.17 / 08.01.2023
==================

* [Added](https://github.com/catamphetamine/libphonenumber-js/issues/420) `PhoneNumber.getPossibleCountries()` function. It returns a list of countries this phone number could possibly belong to. Can be used when parsing complete international phone numbers containing a "calling code" that is shared between several countries. If parsing such a phone number returns `country: undefined` then `getPossibleCountries()` function could be used to somehow speculate about what country could this phone number possibly belong to.

1.10.0 / 18.05.2022
==================

* Migrated the library to use ["ES Modules" export](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/42). This shouldn't break anyone's code and it makes it more modern since people asked about this feature.

1.9.48 / 06.02.2022
==================

* Merged a [pull request](https://gitlab.com/catamphetamine/libphonenumber-js/-/merge_requests/8) that [changed the declaration](https://github.com/catamphetamine/libphonenumber-js/issues/170#issuecomment-1030821520) of basic "string" types like `E164Number`, `NationalNumber`, `Extension`, etc.

1.9.45 / xx.01.2022
==================

* Added `AsYouType.getNumberValue()` function. The function will be [used](https://gitlab.com/catamphetamine/react-phone-number-input/-/issues/113) in `react-phone-number-input` component. Returns the phone number in [`E.164`](https://en.wikipedia.org/wiki/E.164) format. For example, for country `"US"` and input `"(222) 333-4444"` it will return `"+12223334444"`. Will return `undefined` if no digits have been input, or when inputting a phone number in national format and no default country or default "country calling code" have been set.

1.9.42 / 05.11.2021
==================

* Added a better called alias for `metadata.full.json` — `metadata.max.json`.

1.9.40 / 02.11.2021
==================

* Improved [format selection](https://gitlab.com/catamphetamine/react-phone-number-input/-/issues/93) in `AsYouType` formatter: previously it chose the first one before there were at least 3 national (significant) number digits, now it starts filtering out formats right from the start of the national (significant) number.

1.9.36 / 05.10.2021
==================

* Added a [`setExt(ext: string)`](https://gitlab.com/catamphetamine/libphonenumber-js/#setextext-string) function of a `PhoneNumber` class instance. It could be useful when formatting phone numbers stored as two separate fields: the phone number itself and the extension part.

1.9.27 / 09.09.2021
==================

* [Added](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/45) TypeScript "typings" on the exported `Metadata` class. Also rewrote `Metadata` class API [docs](https://gitlab.com/catamphetamine/libphonenumber-js#metadata) and the description of [`leading_digits`](https://gitlab.com/catamphetamine/libphonenumber-js/blob/master/METADATA.md#leading_digits) metadata property.

* TypeScript `Metadata` exported type was renamed to `MetadataJson` so that the `Metadata` class type could be exported as `Metadata`.

1.9.26 / 05.09.2021
==================

* [Added](https://github.com/catamphetamine/libphonenumber-js/issues/406) `validatePhoneNumberLength()` function: same as `isPossiblePhoneNumber()` but tells the actual reason why a phone number is not possible: `TOO_SHORT`, `TOO_LONG`, `INVALID_LENGTH`, etc.

```js
validatePhoneNumberLength('abcde') === 'NOT_A_NUMBER'
validatePhoneNumberLength('444 1 44') === 'INVALID_COUNTRY'
validatePhoneNumberLength('444 1 44', 'TR') === 'TOO_SHORT'
validatePhoneNumberLength('444 1 444', 'TR') === undefined
validatePhoneNumberLength('444 1 4444', 'TR') === 'INVALID_LENGTH'
validatePhoneNumberLength('444 1 44444', 'TR') === 'INVALID_LENGTH'
validatePhoneNumberLength('444 1 444444', 'TR') === undefined
validatePhoneNumberLength('444 1 4444444444', 'TR') === 'TOO_LONG'
```

1.9.20 / 07.06.2021
==================

* [Changed](https://github.com/google/libphonenumber/commit/c6277266fba8223cfc610cfb1e999deb9f876d65) formatting numbers in `IDD` format to always use the preferred IDD prefix (if defined), not just in cases when a country has multiple IDD prefixes. This means that it will output `8~10` as the prefix instead of `810` for some regions (like Uzbekistan) that have this tilde in their IDD prefix (the tilde designates that the user should wait before continuing to dial).

1.9.11 / 10.02.2021
==================

* [Added](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/29) `extract: false` option on `parsePhoneNumberFromString()`: it enables a bit "stricter" parsing in a way that it attempts to parse the entire text as a phone number rather than extracting a phone number from text. For example, with `extract: false` option, `"(213) 373-4253"` is parsed as a valid phone number, but `"Call: (213) 373-4253"` is not, because the `"Call: "` part doesn't automatically get trimmed in this case. If there's version `2.x`, I guess `extract: false` will be the default behavior because it looks more appropriate than the default "extract" behavior of Google's `libphonenumber`.

* Added `isPossiblePhoneNumber()` and `isValidPhoneNumber()` functions, which are basically shortucts to `parsePhoneNumberFromString(text, { extract: false })` and then `.isValid()`/`.isPossible()`.

1.9.5 / 01.12.2020
==================

* Fixed the [issue](https://gitlab.com/catamphetamine/libphonenumber-js/-/merge_requests/4) with `findPhoneNumbersInText()` returning incorrect `startAt` and `endsAt` positions in some cases.

1.9.4 / 13.11.2020
==================

* Refactored the main ES6 export in order to support "tree shaking".

1.9.3 / 11.11.2020
==================

* Added `AsYouType.getChars()` method.

* Added formatting of international phone numbers that have been input without a leading `+`.

1.9.2 / 08.11.2020
==================

* Metadata `version` is now an integer instead of a semver version. Semver versions of previously generated metadata are automatically converted into an integer version.

1.9.1 / 08.11.2020
==================

* Merged the latest Google's [patch](https://github.com/google/libphonenumber/commit/55b2646ec9393f4d3d6661b9c82ef9e258e8b829) on parsing phone number extensions.

1.9.0 / 08.11.2020
==================

* Refactored `AsYouType` formatter.

* (could be a breaking change for some) Some people might have used some of the _undocumented_ `AsYouType` instance properties like `.countryCallingCode`, `.nationalNumber`, etc: those have been moved to a new `.state` object. The `.state` object is also not part of the public API, so developers shouldn't use it: use the documented getter methods instead. The `.country` property of `AsYouType` instance still stays: not because it hasn't been moved (it has been and is emulated), but because it has been part of an official (now legacy) API of `AsYouType` formatter.

* (misc) Renamed `asYouType` instance method `getCountryCallingCode()` to `getCountryCode()`. The older name still works.

* (could be a _build-time_ breaking change for custom metadata) For those who were generating custom metadata, the `libphonenumber-generate-metadata` console command has been moved to a separate package called `libphonenumber-metadata-generator`. The applications that're using it should do `npm install libphonenumber-metadata-generator --save-dev` and then use the new `libphonenumber-metadata-generator` command instead of the old one (only the name changed). [See instructions](https://gitlab.com/catamphetamine/libphonenumber-metadata-generator).

1.8.6 / 05.11.2020
==================

* Refactored `AsYouType` formatter.

* [Fixed](https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/23) `AsYouType` formatter not formatting numbers in some cases like, for example, certain types of Argentinian mobile numbers.

<!-- * Found out that all previous `metadata` was missing `domestic_carrier_code_formatting_rule` that is used in a few countries (like Argentina) when formatting phone numbers containing "carrier codes". It has been added now. -->

* `humanReadable` option of `"IDD"` formatting has been removed: now it's always `true`. The rationale is that Google's `formatOutOfCountryCallingNumber()` original function always formats in "human readable" format.

1.8.3 / 03.10.2020
==================

* (advanced) Fixed `metadata.mobile.json` and generating "custom" metadata: now it won't include non-relevant phone number types. Previously, `metadata.mobile.json` (and any other "custom"-generated metadata) included all phone number types for cases when there're several countries corresponding to the same country calling code (for example, `US` and `CA`). So, in case of `metadata.mobile.json`, for `DE` it only contained mobile phone number type, but for `US` and `CA` it contained all phone number types (this has been unnoticed until this release). Now it only contains mobile phone number types for any country, as it's supposed to be. This change didn't result in any significant "mobile" metadata size reduction: just `105 KB` -> `95 KB`.

1.8.1 / 23.09.2020
==================

* Renamed `parsePhoneNumber()` named export to `parsePhoneNumberWithError()`. The older name still works.

1.8.0 / 22.09.2020
==================

* Promoted `parsePhoneNumberFromString()` named export to a default export due to the name being too verbose.

1.7.50 / 05.04.2020
===================

* [Added](https://github.com/catamphetamine/libphonenumber-js/issues/388#issuecomment-609036293) some utility functions to `AsYouType`:

```js
/**
 * Returns `true` if the phone number is being input in international format.
 * In other words, returns `true` if and only if the parsed phone number starts with a `"+"`.
 * @return {boolean}
 */
isInternational()

/**
 * Returns the "country calling code" part of the phone number.
 * Returns `undefined` if the number is not being input in international format.
 * Returns "country calling code" for "non-geographic" phone numbering plans too.
 * @return {string} [countryCallingCode]
 */
getCountryCallingCode()

/**
 * Returns a two-letter country code of the phone number.
 * Returns `undefined` for "non-geographic" phone numbering plans.
 * Returns `undefined` if no phone number has been input yet.
 * @return {string} [country]
 */
getCountry()

/**
 * Returns `true` if the phone number is "possible".
 * Is just a shortcut for `PhoneNumber.isPossible()`.
 * @return {boolean}
 */
isPossible()

/**
 * Returns `true` if the phone number is "valid".
 * Is just a shortcut for `PhoneNumber.isValid()`.
 * @return {boolean}
 */
isValid()
```

1.7.38 / 04.02.2020
===================

* Removed the `"001"` country code ("Non-Geographic Entity"): now in case of "non-geographic" phone numbers their `country` is just `undefined`. Instead, `PhoneNumber` class has an `.isNonGeographic()` method.

* Fixed "non-geographic" numbers `.isPossible() === false` bug.

1.7.35 / 03.02.2020
===================

* Fixed "Non-Geographic Entities" (`001` country code).

1.7.32 / 03.02.2020
===================

* Refactored the code. Mostly `AsYouType` formatter. `AsYouType.input()` no longer accepts "falsy" values like `null`: instead, it only accepts strings.

* Fixed `AsYouType` formatter bugs ([#318](https://github.com/catamphetamine/libphonenumber-js/issues/318)).

* Added `nationalPrefix: boolean` option to `PhoneNumber.format()` — Some phone numbers can be formatted both with national prefix and without it. In such cases the library defaults to "with national prefix" (for legacy reasons). Pass `nationalPrefix: false` option to force formatting without national prefix in such cases.

* Renamed `findNumbers(text, { v2: true })` to `findPhoneNumbersInText(text)`, and `searchNumbers(text, { v2: true })` to `searchPhoneNumbersInText(text)`.

1.7.27 / 18.11.2019
===================

  * Added `getCountries()` function that returns a list of all available two-letter country codes. This is to prevent some users from having to deal with `Unknown country` error.

1.7.6 / 11.01.2019
==================

  * `findNumbers()`, `searchNumbers()`, `PhoneNumberMatcher` don't throw "Unknown country" error anymore: a non-existent country is simply ignored instead. Same goes for `getExampleNumber()` and `getExtPrefix()`.

  * `parsePhoneNumberFromString()` doesn't return `undefined` if a non-existent default country is passed: it simply ignores such country instead and still parses international numbers.

  * Added `isSupportedCountry(country)` function.

  * Added CDN bundles for `min`/`max`/`mobile` sub-packages.

  * Moved demo to `max` metadata (was `min` previously).

  * Added TypeScript definitions for `min`/`max`/`mobile`/`core` sub-packages.

1.7.1 / 01.12.2018
==================

  * Added `/min`, `/max`, `/mobile` and `/custom` subpackages pre-wired with different flavors of metadata. See the relevant readme section for more info.

  * Added `parsePhoneNumberFromString()` function (which doesn't throw but instead returns `undefined`).

1.7.0 / 31.12.2018
==================

  * Refactored the code to remove cyclic dependencies which caused warnings on React Native. It's not a breaking change but it's still a big code diff overall so incremented the "minor" version number.

1.6.2 / 18.10.2018
==================

  * Support Russian extension character "доб" as a valid one while parsing the numbers.

1.6.1 / 18.10.2018
==================

  * Added `.getNumber()` method to `AsYouType` formatter instance. Returns a `PhoneNumber`.

1.6.0 / 17.10.2018
==================

  * Added `parsePhoneNumber()` function and `PhoneNumber` class.

  * Added `v2: true` option to `findNumbers()` function.

  * Added `getExampleNumber()` function.

  * Added `isPossibleNumber()` function.

  * In `formatNumber()` renamed `National` to `NATIONAL` and `International` to `INTERNATIONAL`. The older variants still work but are considered deprecated.

  * (metadata file internal format breaking change) (doesn't affect users of this library) If anyone was using metadata files from this library bypassing the library functions (i.e. those who parsed `metadata.min.json` file manually) then there's a new internal optimization introduced in this version: previously `formats` were copy-pasted for each country of the same region (e.g. `NANPA`) while now the `formats` are only defined on the "main" country for region and other countries simply read the `formats` from it at runtime. This reduced the default metadata file size by 5 kilobytes.

1.5.0 / 26.09.2018
==================

  * Deprecated `findPhoneNumbers()`, `searchPhoneNumbers()` and `PhoneNumberSearch`. Use `findNumbers()`, `searchNumbers()` and `PhoneNumberMatcher` instead. The now-deprecated functions were a half-self-made implementation of Google's Java `findNumbers()` until the Java code was ported into javascript and passed tests. The port of Google's Java implementation is supposed to find numbers more correctly. It hasn't been tested by users in production yet, but the same tests as for the previous implementation of `findPhoneNumbers()` pass, so seems that it can be used in production.

1.4.6 / 12.09.2018
==================

  * Fixed `formatNumber('NATIONAL')` not formatting national phone numbers with a national prefix when it's marked as optional (e.g. Russia). Before it didn't add national prefix when formatting national numbers if national prefix was marked as optional. Now it always adds national prefix when formatting national numbers even when national prefix is marked as optional.

1.4.5 / 07.09.2018
==================

  * A bug in `matches_entirely` was found by a user which resulted in incorrect regexp matching in some cases, e.g. when there was a `|` in a regexp. This could cause incorrect `parseNumber()` results, or any other weird behaviour.

1.4.0 / 03.08.2018
==================

  * Changed the output of `AsYouType` formatter. E.g. before for `US` and input `21` it was outputting `(21 )` which is not good for phone number input (not intuitive and is confusing). Now it will not add closing braces which haven't been reached yet by the input cursor and it will also strip the corresponding opening braces, so for `US` and input `21` it now is just `21`, and for `213` it is `(213)`.

  * (could be a breaking change for those who somehow used `.template` property of an `AsYouType` instance) Due to the change in `AsYouType` formatting the `.template` property no longer strictly corresponds to the output, e.g. for `US` and input `21` the output is now `21` but the `.template` is still `(xxx) xxx-xxxx` like it used to be in the older versions when the output was `(21 )`. Therefore, a new function has been added to `AsYouType` instance called `.getTemplate()` which will return the _partial_ template for the currently input value, so for input `21` the output will be `21` and `.getTemplate()` will return `xx`, and for input `213` the output will be `(213)` and `.getTemplate()` will return `(xxx)`. So there is this difference between the new `.getTemplate()` function and the old `.template` property: the old `.template` property always returns the template for a fully entered phone number and the new `.getTemplate()` function always returns the template for the _partially_ entered phone number, i.e. for the partially entered number `(213) 45` it will return template `(xxx) xx` so it's a one-to-one correspondence now.

1.3.0 / 25.07.2018
==================

  * Fixed `parseNumber()`, `isValidNumber()` and `getNumberType()` in some rare cases (made them a bit less strict where it fits): previously they were treating `defaultCountry` argument as "the country" in case of local numbers, e.g. `isValidNumber('07624 369230', 'GB')` would be `false` because `07624 369230` number belongs to `IM` (the Isle of Man). While `IM` is not `GB` it should still be `true` because `GB` is the _default_ country, without it necessarily being _the_ country.

  * Added a new function `isValidNumberForRegion(number, country)` which mimics [Google's `libphonenumber`'s one](https://github.com/googlei18n/libphonenumber/blob/master/FAQ.md#when-should-i-use-isvalidnumberforregion).

1.2.13 / 30.05.2018
===================

  * Fixed a previously unnoticed [bug](https://github.com/catamphetamine/libphonenumber-js/issues/217) regarding parsing RFC3966 phone URIs: previously `:` was mistakenly being considered a key-value separator instead of `=`. E.g. it was parsing RFC3966 phone numbers as `tel:+78005553535;ext:123` instead of `tel:+78005553535;ext=123`. The bug was found and reported by @cdunn.

1.2.6 / 12.05.2018
===================

  * Removed `parseNumber()`'s `fromCountry` parameter used for parsing IDD prefixes: now it uses `defaultCountry` instead. `formatNumber()`'s `fromCountry` parameter stays and is not removed.

1.2.5 / 11.05.2018
===================

  * Optimized metadata a bit: using `0` instead of `null`/`false` and `1` instead of `true`.

1.2.0 / 08.05.2018
===================

  * Added support for [IDD prefixes](https://en.wikipedia.org/wiki/International_direct_dialing) — `parse()` now parses IDD-prefixed phones if `fromCountry` option is passed, `format()` now has an `IDD` format.

1.1.7 / 01.04.2018
===================

  * Added `parseNumber()` and `formatNumber()` aliases for `parse()` and `format()`. Now these are the default ones, and `parse()` and `format()` names are considered deprecated. The rationale is that `parse()` and `format()` function names are too unspecific and can clash with other functions declared in a javascript file. And also searching in a project for `parseNumber` and `formatNumber` is easier than searching in a project for `parse` and `format`.

  * Fixed `parseRFC3966()` and `formatRFC3966()` non-custom exports.

1.1.4 / 15.03.2018
===================

  * `parse()` is now more forgiving when parsing invalid international numbers. E.g. `parse('+49(0)15123020522', 'DE')` doesn't return `{}` and instead removes the invalid `(0)` national prefix from the number.

1.1.1 / 10.03.2018
===================

  * Added `PhoneNumberSearch` class for asynchronous phone number search.

1.1.0 / 09.03.2018
===================

  * Added `findPhoneNumbers` function.

1.0.22 / 13.02.2018
===================

  * Added `parseRFC3966` and `formatRFC3966` functions which are exported.

1.0.18 / 12.02.2018
===================

  * Fixed custom metadata backwards compatibility [bug](https://github.com/catamphetamine/libphonenumber-js/issues/180) introduced in `1.0.16`. All people who previously installed `1.0.16` or `1.0.17` should update.
  * Refactored metadata module which now supports versioning by adding the `version` property to metadata JSON.

1.0.17 / 07.02.2018
===================

  * Fixed `RFC3966` format not prepending `tel:` to the output.
  * Renamed `{ possible: true }` option to `{ extended: true }` and the result is now more verbose (see the README).
  * Added `possible_lengths` property in metadata: metadata generated using previous versions of the library should be re-generated with then new version.

1.0.16 / 07.02.2018
===================

  * (experimental) Added `{ possible: true }` option for `parse()` for parsing "possible numbers" which are not considered valid (like Google's demo does). E.g. `parse('+71111111111', { possible: true }) === { countryCallingCode: '7', phone: '1111111111', possible: true }` and `format({ countryCallingCode: '7', phone: '1111111111' }, 'E.164') === '+71111111111'`.
  * `getPhoneCode` name is deprecated, use `getCountryCallingCode` instead.
  * `getPhoneCodeCustom` name is deprecated, use `getCountryCallingCodeCustom` instead.
  * `AsYouType.country_phone_code` renamed to `AsYouType.countryCallingCode` (but no one should have used that property).

1.0.0 / 21.01.2018
==================

  * If `country: string` argument is passed to `parse()` now it becomes "the default country" rather than "restrict to country" ("restrict to country" option is gone).
  * `parse()` `options` argument changed: it's now an undocumented feature and can have only a single option inside — `defaultCountry: string` — which should be passed as a string argument instead.
  * Removed all previously deprecated stuff: all underscored exports (`is_valid_number`, `get_number_type` and `as_you_type`), lowercase exports for `asYouType` and `asYouTypeCustom` (use `AsYouType` and `AsYouTypeCustom` instead), `"International_plaintext"` format (use `"E.164"` instead).
  * Integer phone numbers no longer [get automatically converted to strings](https://github.com/googlei18n/libphonenumber/blob/master/FALSEHOODS.md).
  * `parse()`, `isValidNumber()`, `getNumberType()` and `format()` no longer accept `undefined` phone number argument: it must be either a string or a parsed number object having a string `phone` property.

0.4.52 / 21.01.2018
===================

  * Added `formatExtension(number, extension)` option to `format()`

0.4.50 / 20.01.2018
===================

  * Added support for phone number extensions.
  * `asYouType` name is deprecated, use `AsYouType` instead (same goes for `asYouTypeCustom`).
  * `is_valid_number`, `get_number_type` and `as_you_type` names are deprecated, use camelCased names instead.
  * `International_plaintext` format is deprecated, use `E.164` instead.
  * Added `RFC3966` format for phone number URIs (`tel:+1213334455;ext=123`).

0.4.2 / 30.03.2017
===================

  * Added missing `getNumberTypeCustom` es6 export

0.4.0 / 29.03.2017
===================

  * Removed `.valid` from "as you type" formatter because it wasn't reliable (gave false negatives). Use `isValidNumber(value)` for phone number validation instead.

0.3.11 / 07.03.2017
===================

  * Fixed a bug when "as you type" formatter incorrectly formatted the input using non-matching phone number formats

0.3.8 / 25.02.2017
===================

  * Loosened national prefix requirement when parsing (fixed certain Brazilian phone numbers parsing)

0.3.6 / 16.02.2017
===================

  * Added more strict validation to `isValidNumber`
  * Fixed CommonJS export for `getNumberType`

0.3.5 / 15.02.2017
===================

  * Now exporting `getNumberType` function

0.3.0 / 29.01.2017
===================

  * Removed `libphonenumber-js/custom.es6` exported file: now everything should be imported from the root package in ES6-capable bundlers (because tree-shaking actually works that way)
  * Now custom functions like `parse`, `format` and `isValidNumber` are not bound to custom metadata: it's passed as the last argument instead. And custom `asYouType` is now not a function — instead, `asYouType` constructor takes an additional `metadata` argument

0.2.29 / 12.01.2017
===================

  * Fixed `update-metadata` utility

0.2.26 / 02.01.2017
===================

  * Added national prefix check for `parse` and `isPhoneValid`

0.2.25 / 30.12.2016
===================

  * A bit more precise `valid` flag for "as you type" formatter

0.2.22 / 28.12.2016
===================

  * Added metadata update `bin` command for end users (see README)
  * Added the ability to include extra regular expressions for finer-grained phone number validation

0.2.20 / 28.12.2016
===================

  * Added the ability to use custom-countries generated metadata as a parameter for the functions exported from this library

0.2.19 / 25.12.2016
===================

  * Small fix for "as you type" to not prepend national prefix to the number being typed

0.2.13 / 23.12.2016
===================

  * Reset `default_country` for "as you type" if the input is an international phone number

0.2.12 / 23.12.2016
===================

  * (misc) Small fix for `format()` when the national number is `undefined`

0.2.10 / 23.12.2016
===================

  * Better "as you type" matching: when the national prefix is optional it now tries both variants — with the national prefix extracted and without

0.2.9 / 22.12.2016
===================

  * Exporting `metadata` and `getPhoneCode()`

0.2.6 / 22.12.2016
===================

  * Fixed a minor bug in "as you type" when a local phone number without national prefix got formatted with the national prefix

0.2.2 / 14.12.2016
===================

  * Fixed a bug when country couldn't be parsed from a phone number in most cases

0.2.1 / 10.12.2016
===================

  * Added `.country_phone_code` readable property to "as you type" formatter

0.2.0 / 02.12.2016
===================

  * "As you type" formatter's `country_code` argument is now `default_country_code`, and it doesn't restrict to the specified country anymore.

0.1.17 / 01.12.2016
===================

  * "As you type" formatter `template` fix for national prefixes (which weren't replaced with `x`-es)

0.1.16 / 01.12.2016
===================

  * "As you type" formatter now formats the whole input passed to the `.input()` function one at a time without splitting it into individual characters (which yields better performance)

0.1.14 / 01.12.2016
===================

  * Added `valid`, `country` and `template` fields to "as you type" instance

0.1.12 / 30.11.2016
===================

  * Managed to reduce metadata size by another 5 KiloBytes removing redundant (duplicate) phone number type regular expressions (because there's no "get phone type" API in this library).

0.1.11 / 30.11.2016
===================

  * Managed to reduce metadata size by 10 KiloBytes removing phone number type regular expressions when `leading_digits` are present.

0.1.10 / 30.11.2016
===================

  * Turned out those numerous bulky regular expressions (`<fixedLine/>`, `<mobile/>`, etc) are actually required to reliably infer country from country calling code and national phone number in cases where there are multiple countries assigned to the same country phone code (e.g. NANPA), so I've included those big regular expressions for those ambiguous cases which increased metadata size by 20 KiloBytes resulting in a total of 90 KiloBytes for the metadata.

0.1.9 / 30.11.2016
===================

  * Small fix for "as you type" formatter: replacing digit placeholders (punctuation spaces) with regular spaces in the output

0.1.8 / 29.11.2016
===================

  * Fixed a bug when national prefix `1` was present in "as you type" formatter for NANPA countries (while it shouldn't have been present)

0.1.7 / 29.11.2016
===================

  * (may be a breaking change) renamed `.clear()` to `.reset()` for "as you type" formatter

0.1.5 / 29.11.2016
===================

  * Better `asYouType` (better than Google's original "as you type" formatter)

0.1.0 / 28.11.2016
===================

  * Added `asYouType` and `isValidNumber`.

0.0.3 / 24.11.2016
===================

  * Added `format` function.

0.0.1 / 24.11.2016
===================

  * Initial release. `parse` function is working.