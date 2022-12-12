<!--

@license Apache-2.0

Copyright (c) 2019 The Stdlib Authors.

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

# Type Declarations

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> TypeScript type declarations for stdlib.

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- Package usage documentation. -->

<section class="installation">

## Installation

```bash
npm install @stdlib/types
```

</section>

<section class="usage">

## Usage

```typescript
/// <reference types="@stdlib/types"/>

import { ArrayLike } from '@stdlib/types/array';

function sum( x: ArrayLike<number> ): number {
    let s = 0.0;
    for ( let i = 0; i < x.length; i++ ) {
        s += x[ i ];
    }
    return s;
}
```

Type declarations are organized as modules. For example, to use iterator type declarations,

```typescript
/// <reference types="@stdlib/types"/>

import { Iterator } from '@stdlib/types/iter';

function sum( iter: Iterator ): number {
    let s = 0.0;
    while ( true ) {
        let v = iter.next();
        if ( v.done ) {
            break;
        }
        s += v.value;
    }
    return s;
}
```

For the complete list of declared modules, see the `index.d.ts` type declaration file.

</section>

<!-- /.usage -->

<!-- Package usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

## Notes

-   In order to use included TypeScript declarations, configure your `tsconfig.json` file accordingly. For example,

    ```text
    {
      "compilerOptions": {
        ...
        "typeRoots": [ "./path/to/@stdlib/types" ],
        ...
      },
      ...
    }
    ```

</section>

<!-- /.notes -->

<!-- Package usage examples. -->

<section class="examples">

</section>

<!-- /.examples -->

<!-- Section to include cited references. If references are included, add a horizontal rule *before* the section. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="references">

</section>

<!-- /.references -->

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/types.svg
[npm-url]: https://npmjs.org/package/@stdlib/types

[test-image]: https://github.com/stdlib-js/types/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/types/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/types/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/types?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/types.svg
[dependencies-url]: https://david-dm.org/stdlib-js/types/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/types/tree/deno
[umd-url]: https://github.com/stdlib-js/types/tree/umd
[esm-url]: https://github.com/stdlib-js/types/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/types/main/LICENSE

</section>

<!-- /.links -->
