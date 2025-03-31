'use strict';

const patternsConfig = require('./patterns.js');

const defaultOptions = {
  leftDelimiter: '{',
  rightDelimiter: '}',
  allowedAttributes: []
};

module.exports = function attributes(md, options_) {
  let options = Object.assign({}, defaultOptions);
  options = Object.assign(options, options_);

  const patterns = patternsConfig(options);

  function curlyAttrs(state) {
    const tokens = state.tokens;

    for (let i = 0; i < tokens.length; i++) {
      for (let p = 0; p < patterns.length; p++) {
        const pattern = patterns[p];
        let j = null; // position of child with offset 0
        const match = pattern.tests.every(t => {
          const res = test(tokens, i, t);
          if (res.j !== null) { j = res.j; }
          return res.match;
        });
        if (match) {
          pattern.transform(tokens, i, j);
          if (pattern.name === 'inline attributes' || pattern.name === 'inline nesting 0') {
            // retry, may be several inline attributes
            p--;
          }
        }
      }
    }
  }

  md.core.ruler.before('linkify', 'curly_attributes', curlyAttrs);
};

/**
 * Test if t matches token stream.
 *
 * @param {array} tokens
 * @param {number} i
 * @param {object} t Test to match.
 * @return {object} { match: true|false, j: null|number }
 */
function test(tokens, i, t) {
  const res = {
    match: false,
    j: null  // position of child
  };

  const ii = t.shift !== undefined
    ? i + t.shift
    : t.position;

  if (t.shift !== undefined && ii < 0) {
    // we should never shift to negative indexes (rolling around to back of array)
    return res;
  }

  const token = get(tokens, ii);  // supports negative ii


  if (token === undefined) { return res; }

  for (const key of Object.keys(t)) {
    if (key === 'shift' || key === 'position') { continue; }

    if (token[key] === undefined) { return res; }

    if (key === 'children' && isArrayOfObjects(t.children)) {
      if (token.children.length === 0) {
        return res;
      }
      let match;
      const childTests = t.children;
      const children = token.children;
      if (childTests.every(tt => tt.position !== undefined)) {
        // positions instead of shifts, do not loop all children
        match = childTests.every(tt => test(children, tt.position, tt).match);
        if (match) {
          // we may need position of child in transform
          const j = last(childTests).position;
          res.j = j >= 0 ? j : children.length + j;
        }
      } else {
        for (let j = 0; j < children.length; j++) {
          match = childTests.every(tt => test(children, j, tt).match);
          if (match) {
            res.j = j;
            // all tests true, continue with next key of pattern t
            break;
          }
        }
      }

      if (match === false) { return res; }

      continue;
    }

    switch (typeof t[key]) {
    case 'boolean':
    case 'number':
    case 'string':
      if (token[key] !== t[key]) { return res; }
      break;
    case 'function':
      if (!t[key](token[key])) { return res; }
      break;
    case 'object':
      if (isArrayOfFunctions(t[key])) {
        const r = t[key].every(tt => tt(token[key]));
        if (r === false) { return res; }
        break;
      }
    // fall through for objects !== arrays of functions
    default:
      throw new Error(`Unknown type of pattern test (key: ${key}). Test should be of type boolean, number, string, function or array of functions.`);
    }
  }

  // no tests returned false -> all tests returns true
  res.match = true;
  return res;
}

function isArrayOfObjects(arr) {
  return Array.isArray(arr) && arr.length && arr.every(i => typeof i === 'object');
}

function isArrayOfFunctions(arr) {
  return Array.isArray(arr) && arr.length && arr.every(i => typeof i === 'function');
}

/**
 * Get n item of array. Supports negative n, where -1 is last
 * element in array.
 * @param {array} arr
 * @param {number} n
 */
function get(arr, n) {
  return n >= 0 ? arr[n] : arr[arr.length + n];
}

// get last element of array, safe - returns {} if not found
function last(arr) {
  return arr.slice(-1)[0] || {};
}
