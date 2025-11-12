# Bytes utility

[![NPM Version][npm-image]][npm-url]
[![NPM Downloads][downloads-image]][downloads-url]
[![Build Status][travis-image]][travis-url]
<!--
[![Test Coverage][coveralls-image]][coveralls-url]
 -->
Utility to parse a size string in bytes (e.g. `'1kB'`, `'2KiB'`) to numeric (`1000`, `2048`) and vice-versa.

This is a fork of the [bytes][bytes-url] module, except it

 * supports all of both the binary and decimal prefixes defined by [ISO/IEC 80000-13:2008][binary-wiki]
 * supports [JEDEC][jedec-wiki], a legacy mode in which metric units have binary values
 * uses decimal metric units by default, which can be overridden per call or by default

TypeScript definitions included.

## Supported Units

Supported units are as follows and are case-insensitive. Note that only the abbreviation will be parsed/formatted, the full names are for the reader's understanding only.

### Metric

Also referred to as SI. See [Compatibility Binary](#compatibility-binary) for legacy definitions.

|      Value       | Abbr |   Name    |
| ---------------- | ---- | --------- |
| 1                | B    | byte      |
| 1000<sup>1</sup> | kB   | kilobyte  |
| 1000<sup>2</sup> | MB   | megabyte  |
| 1000<sup>3</sup> | GB   | gigabyte  |
| 1000<sup>4</sup> | TB   | terabyte  |
| 1000<sup>5</sup> | PB   | petabyte  |
| 1000<sup>6</sup> | EB   | exabyte   |
| 1000<sup>7</sup> | ZB   | zettabyte |
| 1000<sup>8</sup> | YB   | yottabyte |

[More info][metric-wiki]

### Binary

|      Value       | Abbr |   Name    |
| ---------------- | ---- | --------- |
| 1                | B    | byte      |
| 1024<sup>1</sup> | KiB  | kibibyte  |
| 1024<sup>2</sup> | MiB  | mebibyte  |
| 1024<sup>3</sup> | GiB  | gibibyte  |
| 1024<sup>4</sup> | TiB  | tebibyte  |
| 1024<sup>5</sup> | PiB  | pebibyte  |
| 1024<sup>6</sup> | EiB  | exbibyte  |
| 1024<sup>7</sup> | ZiB  | zebibite  |
| 1024<sup>8</sup> | YiB  | yobibite  |

[More info][binary-wiki]

### Compatibility Binary

Also referred to as JEDEC or legacy units.

Overwrites the lower units of the metric system with the commonly misused values, i.e. metric units will be binary instead of decimal.
This is the behavior of e.g. the Windows OS and [bytes][bytes-url].
Units greater than terabyte are not supported.

|      Value       | Abbr |   Name    |
| ---------------- | ---- | --------- |
| 1024<sup>1</sup> | kB   | kilobyte  |
| 1024<sup>2</sup> | MB   | megabyte  |
| 1024<sup>3</sup> | GB   | gigabyte  |
| 1024<sup>4</sup> | TB   | terabyte  |

[More info][jedec-wiki]

# Installation

This is a [Node.js](https://nodejs.org/en/) module available through the
[npm registry](https://www.npmjs.com/). Installation is done using the
[`npm install` command](https://docs.npmjs.com/getting-started/installing-npm-packages-locally):

```bash
npm install bytes-iec
```

# Usage

```js
var bytes = require('bytes-iec');
```

## Modes

Passing a unit type as `mode` parameter in API calls determines

 * the set of units that will be favored by autodetection when no unit is specified
 * the value/size of metric units: Compatibility mode makes them base-2 instead of base-10

| Unit type                                     | `mode`                         |
| --------------------------------------------- | ------------------------------ |
| [Metric](#metric)                             | `'metric'` or `'decimal'`      |
| [Binary](#binary)                             | `'binary'`                     |
| [Compatibility Binary](#compatibility-binary) | `'compatibility'` or `'jedec'` |

## bytes.format(number value, [options]): string|null

Format the given value in bytes into a string. If the value is negative, it's kept as such. If it's a float, it's rounded.

**Arguments**

| Name    | Type     | Description        |
|---------|----------|--------------------|
| value   | `number` | Value in bytes     |
| options | `Object` | Conversion options |

**Options**

| Property           | Type              | Description                                                                                   | Default           |
| ------------------ | ----------------- | --------------------------------------------------------------------------------------------- | ----------------- |
| decimalPlaces      | `number`｜`null`  | Maximum number of decimal places to include in output                                         | `2`               |
| fixedDecimals      | `boolean`｜`null` | Whether to always display the maximum number of decimal places, i.e. preserve trailing zeroes | `false`           |
| thousandsSeparator | `string`｜`null`  | What to separate large numbers with, e.g. `','`, `'.'`, `' '`, ...                            | `''`              |
| unit               | `string`｜`null`  | The unit in which the result will be returned: `'B'`, `'kB'`, `'KiB'`, ...                    | `''` (autodetect) |
| unitSeparator      | `string`｜`null`  | Separator between numeric value and unit                                                      | `''`              |
| mode               | `string`｜`null`  | Which mode to use (see [Modes](#modes))                                                       | `'metric'`        |

**Returns**

| Name    | Type             | Description                                     |
|---------|------------------|-------------------------------------------------|
| results | `string`｜`null` | Returns null upon error, string value otherwise. |

**Example**

```js
bytes(1000);
// output: '1kB'

bytes(1000, {thousandsSeparator: ' '});
// output: '1 000B'

bytes(1024);
// output: '1.02kB'

bytes(1024 * 1.7, {decimalPlaces: 0});
// output: '2KB'

bytes(1000, {unitSeparator: ' '});
// output: '1 kB'

bytes(2048, {mode: 'binary'});
// output: '2 KiB'

bytes(1024 * 1024 * 2, {unit: 'KiB'});
// output: '2048 KiB'

bytes(1024 * 1024 * 2, {unit: 'KB'});
// output: '2097.152 KB'

bytes(1024 * 1024 * 2, {unit: 'KB', mode: 'compatibility'});
// output: '2048 KB'
```

## bytes.parse(string｜number value): number｜null

Parse the string value into an integer in bytes. If no unit is given, or `value`
is a number, it is assumed the value is in bytes.

If the value given has partial bytes, it's truncated (rounded down).

**Arguments**

| Name          | Type   | Description        |
|---------------|--------|--------------------|
| value   | `string`｜`number` | String to parse, or number in bytes |
| options | `Object` | Conversion options |

|       Property       |          Type         | Description | Default |
| -------------------- | --------------------- | ----------- |---------|
| mode   | `string`｜`null` | Which mode to use (see [Modes](#modes)) | `'metric'` |

**Returns**

| Name    | Type        | Description             |
|---------|-------------|-------------------------|
| results | `number`｜`null` | Returns null upon error, value in bytes otherwise. |

**Example**

```js
bytes('1kB');
// output: 1024

bytes('1024');
// output: 1024

bytes('1.0001 kB');
// output: 1000
bytes('1.0001 KiB');
// output: 1024

bytes('1kB', {mode: 'jedec'});
// output: 1024
```

## bytes.withDefaultMode(string mode): object

Returns a new copy of the `bytes-iec` module, but with the given mode as the default.

**Arguments**

| Name          | Type     | Description        |
|---------------|----------|--------------------|
| mode          | `string` | Default mode to use (see [Modes](#modes))   |

**Returns**

| Name    | Type        | Description             |
|---------|-------------|-------------------------|
| results | `object` | Returns the byte.js module, with a default mode. |

**Example**

```js
var bytes = require('bytes').withDefaultMode('jedec');

bytes('1kB');
// output: 1024

bytes('1KiB');
// output: 1024

bytes(1024);
// output: 1 kB

bytes(1024, {mode: 'metric'});
// output: 1.02kB

bytes('1kB', {mode: 'metric'});
// output: 1000
```

# License

[MIT](LICENSE)

<!--
[coveralls-image]: https://badgen.net/coveralls/c/github/visionmedia/bytes.js/master
[coveralls-url]: https://coveralls.io/r/visionmedia/bytes.js?branch=master
-->

[downloads-image]: https://badgen.net/npm/dm/bytes-iec
[downloads-url]: https://npmjs.org/package/bytes-iec
[npm-image]: https://badgen.net/npm/node/bytes-iec
[npm-url]: https://npmjs.org/package/bytes-iec
[travis-image]: https://badgen.net/travis/saevon/bytes.js/master
[travis-url]: https://travis-ci.org/saevon/bytes.js
[bytes-url]: https://github.com/visionmedia/bytes.js
[binary-wiki]: https://en.wikipedia.org/wiki/Binary_prefix
[metric-wiki]: https://en.wikipedia.org/wiki/Metric_prefix
[jedec-wiki]: https://en.wikipedia.org/wiki/JEDEC_memory_standards#Unit_prefixes_for_semiconductor_storage_capacity
