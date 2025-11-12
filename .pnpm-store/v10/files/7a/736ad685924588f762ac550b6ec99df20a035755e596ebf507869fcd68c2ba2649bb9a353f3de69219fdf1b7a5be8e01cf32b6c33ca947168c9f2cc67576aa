## Build Polyfills

This is a collection of syntax and import/export polyfills either copied directly from or heavily inspired by those used
by [Rollup](https://github.com/rollup/rollup) and [Sucrase](https://github.com/alangpierce/sucrase). When either tool
uses one of these polyfills during a build, it injects the function source code into each file needing the function,
which can lead to a great deal of duplication. For our builds, we have therefore implemented something similar to
[`tsc`'s `importHelpers` behavior](https://www.typescriptlang.org/tsconfig#importHelpers): Instead of leaving the
polyfills injected in multiple places, we instead replace each injected function with an `import` or `require`
statement.

Note that not all polyfills are currently used by the SDK, but all are included here for future compatitibility, should
they ever be needed. Also, since we're never going to be calling these directly from within another TS file, their types
are fairly generic. In some cases testing required more specific types, which can be found in the test files.

---

_Code from both Rollup and Sucrase is used under the MIT license, copyright 2017 and 2012-2018, respectively._

_Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:_

_The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software._

_THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE._
