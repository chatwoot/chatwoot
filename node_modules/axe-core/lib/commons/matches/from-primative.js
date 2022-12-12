/**
 * Check if some value matches
 *
 * ```js
 * match.fromPrimative('foo', 'foo') // true, string is the same
 * match.fromPrimative('foo', ['foo', 'bar']) // true, string is included
 * match.fromPrimative('foo', /foo/) // true, string matches regex
 * match.fromPrimative('foo', str => str.toUpperCase() === 'FOO') // true, function return is truthy
 * match.fromPrimative('foo', '/foo/') // true, string matches regex string
 * ```
 *
 * @private
 * @param {String|Boolean|Array|Number|Null|Undefined} someString
 * @param {String|RegExp|Function|Array<String>|Null|Undefined} matcher
 * @returns {Boolean}
 */
function fromPrimative(someString, matcher) {
  const matcherType = typeof matcher;
  if (Array.isArray(matcher) && typeof someString !== 'undefined') {
    return matcher.includes(someString);
  }

  if (matcherType === 'function') {
    return !!matcher(someString);
  }

  // RegExp.test(str) typecasts the str to a String value so doing
  // `/.*/.test(null)` returns true as null is cast to "null"
  if (someString !== null && someString !== undefined) {
    if (matcher instanceof RegExp) {
      return matcher.test(someString);
    }

    // matcher starts and ends with "/"
    if (/^\/.*\/$/.test(matcher)) {
      const pattern = matcher.substring(1, matcher.length - 1);
      return new RegExp(pattern).test(someString);
    }
  }

  return matcher === someString;
}

export default fromPrimative;
