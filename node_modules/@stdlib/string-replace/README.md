<!--

@license Apache-2.0

Copyright (c) 2018 The Stdlib Authors.

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

# Replace

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Replace search occurrences with a replacement string.

<section class="installation">

## Installation

```bash
npm install @stdlib/string-replace
```

</section>

<section class="usage">

## Usage

```javascript
var replace = require( '@stdlib/string-replace' );
```

#### replace( str, search, newval )

Replaces search occurrences with a replacement `string`.

```javascript
var out = replace( 'beep', 'e', 'o' );
// returns 'boop'
```

If provided a `function` as the [third argument][replacer], the function is invoked for each match, and the function's return value is used as the replacement `string`.

```javascript
function replacer( match, p1 ) {
    return '/' + p1 + '/';
}
var str = 'Oranges and lemons';
var out = replace( str, /([^\s]+)/gi, replacer );
// returns '/Oranges/ /and/ /lemons/'
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The function has one notable difference from [`String.prototype.replace`][mdn]. When provided a `string` as the `search` value, the function replaces **all** occurrences. To remove only the first match, use a regular expression.

    ```javascript
    var out = replace( 'beep', /e/, 'o' );
    // returns 'boep'
    ```

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var capitalize = require( '@stdlib/string-capitalize' );
var replace = require( '@stdlib/string-replace' );

var out;
var str;

out = replace( 'beep', 'e', 'o' );
// returns 'boop'

out = replace( 'Hello World', /world/i, 'Mr. President' );
// returns 'Hello Mr. President'

str = 'Oranges and lemons say the bells of St. Clement\'s';
out = replace( str, /([^\s]*)/gi, replacer );
// returns 'Oranges And Lemons Say The Bells Of St. Clement\'s'

function replacer( match, p1 ) {
    return capitalize( p1 );
}
```

</section>

<!-- /.examples -->

* * *

<section class="cli">

## CLI

<section class="installation">

## Installation

To use the module as a general utility, install the module globally

```bash
npm install -g @stdlib/string-replace
```

</section>

<!-- CLI usage documentation. -->

<section class="usage">

### Usage

```text
Usage: replace [options] [<string>] --search=<string> --newval=<string>

Options:

  -h,    --help                Print this message.
  -V,    --version             Print the package version.
         --search string       Search string.
         --newval string       Replacement string.
```

</section>

<!-- /.usage -->

<section class="examples">

### Examples

```bash
$ replace --search='/[eo]/' --newval=a beep
baap
```

To use as a [standard stream][standard-streams],

```bash
$ echo -n 'boop' | replace --search='o' newval='e'
beep
```

</section>

<!-- /.examples -->

</section>

<!-- /.cli -->

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/string-replace.svg
[npm-url]: https://npmjs.org/package/@stdlib/string-replace

[test-image]: https://github.com/stdlib-js/string-replace/actions/workflows/test.yml/badge.svg?branch=v0.0.11
[test-url]: https://github.com/stdlib-js/string-replace/actions/workflows/test.yml?query=branch:v0.0.11

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/string-replace/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/string-replace?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/string-replace.svg
[dependencies-url]: https://david-dm.org/stdlib-js/string-replace/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/string-replace/tree/deno
[umd-url]: https://github.com/stdlib-js/string-replace/tree/umd
[esm-url]: https://github.com/stdlib-js/string-replace/tree/esm
[branches-url]: https://github.com/stdlib-js/string-replace/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/string-replace/main/LICENSE

[mdn]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace

[replacer]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/replace#Specifying_a_function_as_a_parameter

[standard-streams]: https://en.wikipedia.org/wiki/Standard_streams

</section>

<!-- /.links -->
