import { _optionalChain } from './_optionalChain.js';

// https://github.com/alangpierce/sucrase/tree/265887868966917f3b924ce38dfad01fbab1329f
//
// The MIT License (MIT)
//
// Copyright (c) 2012-2018 various contributors (see AUTHORS)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


/**
 * Polyfill for the optional chain operator, `?.`, given previous conversion of the expression into an array of values,
 * descriptors, and functions, in cases where the value of the expression is to be deleted.
 *
 * Adapted from Sucrase (https://github.com/alangpierce/sucrase) See
 * https://github.com/alangpierce/sucrase/blob/265887868966917f3b924ce38dfad01fbab1329f/src/transformers/OptionalChainingNullishTransformer.ts#L15
 *
 * @param ops Array result of expression conversion
 * @returns The return value of the `delete` operator: `true`, unless the deletion target is an own, non-configurable
 * property (one which can't be deleted or turned into an accessor, and whose enumerability can't be changed), in which
 * case `false`.
 */
function _optionalChainDelete(ops) {
  const result = _optionalChain(ops) ;
  // If `result` is `null`, it means we didn't get to the end of the chain and so nothing was deleted (in which case,
  // return `true` since that's what `delete` does when it no-ops). If it's non-null, we know the delete happened, in
  // which case we return whatever the `delete` returned, which will be a boolean.
  return result == null ? true : result;
}

// Sucrase version:
// function _optionalChainDelete(ops) {
//   const result = _optionalChain(ops);
//   // by checking for loose equality to `null`, we catch both `null` and `undefined`
//   return result == null ? true : result;
// }

export { _optionalChainDelete };
//# sourceMappingURL=_optionalChainDelete.js.map
