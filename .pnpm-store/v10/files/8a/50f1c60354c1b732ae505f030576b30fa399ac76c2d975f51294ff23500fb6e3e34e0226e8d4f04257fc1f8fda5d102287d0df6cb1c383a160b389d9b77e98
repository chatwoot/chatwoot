<!--

@license Apache-2.0

Copyright (c) 2022 The Stdlib Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

# format

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Insert supplied variable values into a format string.

<section class="intro">

</section>

<!-- /.intro -->

<section class="installation">

## Installation

```bash
npm install @stdlib/string-format
```

</section>

<section class="usage">

## Usage

```javascript
var format = require( '@stdlib/string-format' );
```

#### format( str, ...args )

Inserts supplied variable values into a format string.

```javascript
var str = 'Hello, %s! My name is %s.';
var out = format( str, 'world', 'Bob' );
// returns 'Hello, world! My name is Bob.'
```

The format string is a string literal containing zero or more conversion specifications, each of which results in a string value being inserted to the output string. A conversion specification consists of a percent sign (`%`) followed by one or more of the following flags, width, precision, and conversion type characters. It thus takes the following form:

```text
%[flags][width][.precision]specifier
```

Arguments following the format string are used to replace the placeholders in the format string. The number of arguments following the format string should be equal to the number of placeholders in the format string.

```javascript
var str = '%s %s';
var out = format( str, 'Hello', 'World' );
// returns 'Hello World'
```

To supply arguments in a different order than they appear in the format string, positional placeholders as indicated by a `$` character in the format string are used. In this case, the conversion specification takes the form:

```text
%[pos$][flags][width][.precision]specifier
```

```javascript
var str = '%3$s %2$s %1$s';
var out = format( str, 'foo', 'bar', 'baz' );
// returns 'baz bar foo'
```

The following table summarizes the supported specifiers:

| type | description                        | example      |
| ---- | ---------------------------------- | ------------ |
| s    | string                             | beep boop    |
| c    | character                          | a            |
| d, i | signed decimal integer             | -12          |
| u    | unsigned decimal integer           | 390          |
| b    | unsigned binary integer            | 11011011     |
| o    | unsigned octal integer             | 510          |
| x    | unsigned hexadecimal (lowercase)   | 7b           |
| X    | unsigned hexadecimal (uppercase)   | 7B           |
| f, F | decimal floating point             | 390.24       |
| e    | scientific notation (lowercase)    | 3.9e+1       |
| E    | scientific notation (uppercase)    | 3.9E+1       |
| g    | shortest representation (`e`/`f`)  | 3.9          |
| G    | shortest representation (`E`/`F`)  | 3.9          |

```javascript
var str = '%i written as a binary number is %b.';
var out = format( str, 9, 9 );
// returns '9 written as a binary number is 1001.'

str = '%i written as an octal number is %o.';
out = format( str, 17, 17 );
// returns '17 written as an octal number is 21.'

str = '%i written as a hexadecimal number is %x.';
out = format( str, 255, 255 );
// returns '255 written as a hexadecimal number is ff.'

str = '%i written as a hexadecimal number is %X (uppercase letters).';
out = format( str, 255, 255 );
// returns '255 written as a hexadecimal number is FF (uppercase letters).'

str = '%i written as a floating point number with default precision is %f!';
out = format( str, 8, 8 );
// returns '8 written as a floating point number with default precision is 8.000000!'

str = 'Scientific notation: %e';
out = format( str, 3.14159 );
// returns 'Scientific notation: 3.141590e+00'

str = 'Scientific notation: %E (uppercase).';
out = format( str, 3.14159 );
// returns 'Scientific notation: 3.141590E+00 (uppercase).'

str = '%g (shortest representation)';
out = format( str, 3.14159 );
// returns '3.14159'
```

A conversion specification may contain zero or more flags, which modify the behavior of the conversion. The following flags are supported:

| flag  | description                                                                                |
| ----- | ------------------------------------------------------------------------------------------ |
| -     | left-justify the output within the given field width by padding with spaces on the right   |
| 0     | left-pad the output with zeros instead of spaces when padding is required                  |
| #     | use an alternative format for `o` and `x` conversions                                      |
| +     | prefix the output with a plus (+) or minus (-) sign even if the value is a positive number |
| space | prefix the value with a space character if no sign is written                              |

```javascript
var str = 'Always prefix with a sign: %+i';
var out = format( str, 9 );
// returns 'Always prefix with a sign: +9'

out = format( str, -9 );
// returns 'Always prefix with a sign: -9'

str = 'Only prefix with a sign if negative: %i';
out = format( str, 6 );
// returns 'Only prefix with a sign if negative: 6'

out = format( str, -6 );
// returns 'Only prefix with a sign if negative: -6'

str = 'Prefix with a sign if negative and a space if positive: % i';
out = format( str, 3 );
// returns 'Prefix with a sign if negative and a space if positive:  3'

out = format( str, -3 );
// returns 'Prefix with a sign if negative and a space if positive: -3'
```

The `width` may be specified as a decimal integer representing the minimum number of characters to be written to the output. If the value to be written is shorter than this number, the result is padded with spaces on the left. The value is not truncated even if the result is larger. Alternatively, the `width` may be specified as an asterisk character (`*`), in which case the argument preceding the conversion specification is used as the minimum field width.

```javascript
var str = '%5s';
var out = format( str, 'baz' );
// returns '  baz'

str = '%-5s';
out = format( str, 'baz' );
// returns 'baz  '

str = '%05i';
out = format( str, 2 );
// returns '00002'

str = '%*i';
out = format( str, 5, 2 );
// returns '   2'
```

The `precision` may be specified as a decimal integer or as an asterisk character (`*`), in which case the argument preceding the conversion specification is used as the precision value. The behavior of the `precision` differs depending on the conversion type:

-   For `s` specifiers, the `precision` specifies the maximum number of characters to be written to the output.
-   For floating point specifiers (`f`, `F`, `e`, `E`), the `precision` specifies the number of digits after the decimal point to be written to the output (by default, this is `6`).
-  For `g` and `G` specifiers, the `precision` specifies the maximum number of significant digits to be written to the output.
-  For integer specifiers (`d`, `i`, `u`, `b`, `o`, `x`, `X`), the `precision` specifies the minimum number of digits to be written to the output. If the value to be written is shorter than this number, the result is padded with zeros on the left. The value is not truncated even if the result is longer. For 

Alternatively, the `precision` may be specified as an asterisk character (`*`), in which case the argument preceding the conversion specification is used as the minimum number of digits.

```javascript
var str = '%5.2s';
var out = format( str, 'baz' );
// returns '   ba'

str = 'PI: ~%.2f';
out = format( str, 3.14159 );
// returns 'PI: ~3.14'

str = 'Agent %.3i';
out = format( str, 7 );
// returns 'Agent 007'
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var format = require( '@stdlib/string-format' );

var out = format( '%s %s!', 'Hello', 'World' );
// returns 'Hello World!'

out = format( 'Pi: ~%.2f', 3.141592653589793 );
// returns 'Pi: ~3.14'

out = format( '%-10s %-10s', 'a', 'b' );
// returns 'a       b       '

out = format( '%10s %10s', 'a', 'b' );
// returns '       a       b'

out = format( '%2$s %1$s %3$s', 'b', 'a', 'c' );
// returns 'a b c'
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

</section>

<!-- /.related -->

<!-- Section for all links. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->


<section class="main-repo" >

* * *

## Notice

This package is part of [stdlib][stdlib], a standard library for JavaScript and Node.js, with an emphasis on numerical and scientific computing. The library provides a collection of robust, high performance libraries for mathematics, statistics, streams, utilities, and more.

For more information on the project, filing bug reports and feature requests, and guidance on how to develop [stdlib][stdlib], see the main project [repository][stdlib].

#### Community

[![Chat][chat-image]][chat-url]

---

## License

See [LICENSE][stdlib-license].


## Copyright

Copyright &copy; 2016-2022. The Stdlib [Authors][stdlib-authors].

</section>

<!-- /.stdlib -->

<!-- Section for all links. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="links">

[npm-image]: http://img.shields.io/npm/v/@stdlib/string-format.svg
[npm-url]: https://npmjs.org/package/@stdlib/string-format

[test-image]: https://github.com/stdlib-js/string-format/actions/workflows/test.yml/badge.svg?branch=v0.0.3
[test-url]: https://github.com/stdlib-js/string-format/actions/workflows/test.yml?query=branch:v0.0.3

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/string-format/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/string-format?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/string-format.svg
[dependencies-url]: https://david-dm.org/stdlib-js/string-format/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/string-format/tree/deno
[umd-url]: https://github.com/stdlib-js/string-format/tree/umd
[esm-url]: https://github.com/stdlib-js/string-format/tree/esm
[branches-url]: https://github.com/stdlib-js/string-format/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/string-format/main/LICENSE

</section>

<!-- /.links -->
