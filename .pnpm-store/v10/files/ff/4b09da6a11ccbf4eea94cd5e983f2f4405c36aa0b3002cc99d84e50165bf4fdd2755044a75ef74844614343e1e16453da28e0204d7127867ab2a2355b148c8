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

# Non-Enumerable Read-Only

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> [Define][@stdlib/utils/define-property] a non-enumerable **read-only** property.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-define-nonenumerable-read-only-property
```

</section>

<section class="usage">

## Usage

```javascript
var setNonEnumerableReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );
```

#### setNonEnumerableReadOnly( obj, prop, value )

[Defines][@stdlib/utils/define-property] a non-enumerable **read-only** property.

<!-- run throws: true -->

```javascript
var obj = {};

setNonEnumerableReadOnly( obj, 'foo', 'bar' );

obj.foo = 'boop';
// throws <Error>
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   Non-enumerable read-only properties are **non-configurable**.

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var setNonEnumerableReadOnly = require( '@stdlib/utils-define-nonenumerable-read-only-property' );

function Foo( name ) {
    if ( !(this instanceof Foo) ) {
        return new Foo( name );
    }
    setNonEnumerableReadOnly( this, 'name', name );
    return this;
}

var foo = new Foo( 'beep' );

try {
    foo.name = 'boop';
} catch ( err ) {
    console.error( err.message );
}
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/utils/define-nonenumerable-property`][@stdlib/utils/define-nonenumerable-property]</span><span class="delimiter">: </span><span class="description">define a non-enumerable property.</span>
-   <span class="package-name">[`@stdlib/utils/define-nonenumerable-read-only-accessor`][@stdlib/utils/define-nonenumerable-read-only-accessor]</span><span class="delimiter">: </span><span class="description">define a non-enumerable read-only accessor.</span>
-   <span class="package-name">[`@stdlib/utils/define-nonenumerable-read-write-accessor`][@stdlib/utils/define-nonenumerable-read-write-accessor]</span><span class="delimiter">: </span><span class="description">define a non-enumerable read-write accessor.</span>
-   <span class="package-name">[`@stdlib/utils/define-nonenumerable-write-only-accessor`][@stdlib/utils/define-nonenumerable-write-only-accessor]</span><span class="delimiter">: </span><span class="description">define a non-enumerable write-only accessor.</span>
-   <span class="package-name">[`@stdlib/utils/define-read-only-property`][@stdlib/utils/define-read-only-property]</span><span class="delimiter">: </span><span class="description">define a read-only property.</span>

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

## Copyright

Copyright &copy; 2016-2022. The Stdlib [Authors][stdlib-authors].

</section>

<!-- /.stdlib -->

<!-- Section for all links. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="links">

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-define-nonenumerable-read-only-property.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-define-nonenumerable-read-only-property

[test-image]: https://github.com/stdlib-js/utils-define-nonenumerable-read-only-property/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-define-nonenumerable-read-only-property/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-define-nonenumerable-read-only-property/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-define-nonenumerable-read-only-property?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-define-nonenumerable-read-only-property.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-define-nonenumerable-read-only-property/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-define-nonenumerable-read-only-property/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-define-nonenumerable-read-only-property/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-define-nonenumerable-read-only-property/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[@stdlib/utils/define-property]: https://www.npmjs.com/package/@stdlib/utils-define-property

<!-- <related-links> -->

[@stdlib/utils/define-nonenumerable-property]: https://www.npmjs.com/package/@stdlib/utils-define-nonenumerable-property

[@stdlib/utils/define-nonenumerable-read-only-accessor]: https://www.npmjs.com/package/@stdlib/utils-define-nonenumerable-read-only-accessor

[@stdlib/utils/define-nonenumerable-read-write-accessor]: https://www.npmjs.com/package/@stdlib/utils-define-nonenumerable-read-write-accessor

[@stdlib/utils/define-nonenumerable-write-only-accessor]: https://www.npmjs.com/package/@stdlib/utils-define-nonenumerable-write-only-accessor

[@stdlib/utils/define-read-only-property]: https://www.npmjs.com/package/@stdlib/utils-define-read-only-property

<!-- </related-links> -->

</section>

<!-- /.links -->
