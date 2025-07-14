(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.markdownItAttrs = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
'use strict';

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }
var patternsConfig = require('./patterns.js');
var defaultOptions = {
  leftDelimiter: '{',
  rightDelimiter: '}',
  allowedAttributes: []
};
module.exports = function attributes(md, options_) {
  var options = Object.assign({}, defaultOptions);
  options = Object.assign(options, options_);
  var patterns = patternsConfig(options);
  function curlyAttrs(state) {
    var tokens = state.tokens;
    var _loop = function _loop(i) {
      for (var p = 0; p < patterns.length; p++) {
        var pattern = patterns[p];
        var j = null; // position of child with offset 0
        var match = pattern.tests.every(function (t) {
          var res = test(tokens, i, t);
          if (res.j !== null) {
            j = res.j;
          }
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
    };
    for (var i = 0; i < tokens.length; i++) {
      _loop(i);
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
  var res = {
    match: false,
    j: null // position of child
  };

  var ii = t.shift !== undefined ? i + t.shift : t.position;
  if (t.shift !== undefined && ii < 0) {
    // we should never shift to negative indexes (rolling around to back of array)
    return res;
  }
  var token = get(tokens, ii); // supports negative ii

  if (token === undefined) {
    return res;
  }
  var _loop2 = function _loop2() {
    var key = _Object$keys[_i];
    if (key === 'shift' || key === 'position') {
      return "continue";
    }
    if (token[key] === undefined) {
      return {
        v: res
      };
    }
    if (key === 'children' && isArrayOfObjects(t.children)) {
      var _ret2 = function () {
        if (token.children.length === 0) {
          return {
            v: {
              v: res
            }
          };
        }
        var match;
        var childTests = t.children;
        var children = token.children;
        if (childTests.every(function (tt) {
          return tt.position !== undefined;
        })) {
          // positions instead of shifts, do not loop all children
          match = childTests.every(function (tt) {
            return test(children, tt.position, tt).match;
          });
          if (match) {
            // we may need position of child in transform
            var j = last(childTests).position;
            res.j = j >= 0 ? j : children.length + j;
          }
        } else {
          var _loop3 = function _loop3(_j) {
            match = childTests.every(function (tt) {
              return test(children, _j, tt).match;
            });
            if (match) {
              res.j = _j;
              // all tests true, continue with next key of pattern t
              return "break";
            }
          };
          for (var _j = 0; _j < children.length; _j++) {
            var _ret3 = _loop3(_j);
            if (_ret3 === "break") break;
          }
        }
        if (match === false) {
          return {
            v: {
              v: res
            }
          };
        }
        return {
          v: "continue"
        };
      }();
      if (_typeof(_ret2) === "object") return _ret2.v;
    }
    switch (_typeof(t[key])) {
      case 'boolean':
      case 'number':
      case 'string':
        if (token[key] !== t[key]) {
          return {
            v: res
          };
        }
        break;
      case 'function':
        if (!t[key](token[key])) {
          return {
            v: res
          };
        }
        break;
      case 'object':
        if (isArrayOfFunctions(t[key])) {
          var r = t[key].every(function (tt) {
            return tt(token[key]);
          });
          if (r === false) {
            return {
              v: res
            };
          }
          break;
        }
      // fall through for objects !== arrays of functions
      default:
        throw new Error("Unknown type of pattern test (key: ".concat(key, "). Test should be of type boolean, number, string, function or array of functions."));
    }
  };
  for (var _i = 0, _Object$keys = Object.keys(t); _i < _Object$keys.length; _i++) {
    var _ret = _loop2();
    if (_ret === "continue") continue;
    if (_typeof(_ret) === "object") return _ret.v;
  }

  // no tests returned false -> all tests returns true
  res.match = true;
  return res;
}
function isArrayOfObjects(arr) {
  return Array.isArray(arr) && arr.length && arr.every(function (i) {
    return _typeof(i) === 'object';
  });
}
function isArrayOfFunctions(arr) {
  return Array.isArray(arr) && arr.length && arr.every(function (i) {
    return typeof i === 'function';
  });
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

},{"./patterns.js":2}],2:[function(require,module,exports){
'use strict';

/**
 * If a pattern matches the token stream,
 * then run transform.
 */
var utils = require('./utils.js');
module.exports = function (options) {
  var __hr = new RegExp('^ {0,3}[-*_]{3,} ?' + utils.escapeRegExp(options.leftDelimiter) + '[^' + utils.escapeRegExp(options.rightDelimiter) + ']');
  return [{
    /**
     * ```python {.cls}
     * for i in range(10):
     *     print(i)
     * ```
     */
    name: 'fenced code blocks',
    tests: [{
      shift: 0,
      block: true,
      info: utils.hasDelimiters('end', options)
    }],
    transform: function transform(tokens, i) {
      var token = tokens[i];
      var start = token.info.lastIndexOf(options.leftDelimiter);
      var attrs = utils.getAttrs(token.info, start, options);
      utils.addAttrs(attrs, token);
      token.info = utils.removeDelimiter(token.info, options);
    }
  }, {
    /**
     * bla `click()`{.c} ![](img.png){.d}
     *
     * differs from 'inline attributes' as it does
     * not have a closing tag (nesting: -1)
     */
    name: 'inline nesting 0',
    tests: [{
      shift: 0,
      type: 'inline',
      children: [{
        shift: -1,
        type: function type(str) {
          return str === 'image' || str === 'code_inline';
        }
      }, {
        shift: 0,
        type: 'text',
        content: utils.hasDelimiters('start', options)
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var endChar = token.content.indexOf(options.rightDelimiter);
      var attrToken = tokens[i].children[j - 1];
      var attrs = utils.getAttrs(token.content, 0, options);
      utils.addAttrs(attrs, attrToken);
      if (token.content.length === endChar + options.rightDelimiter.length) {
        tokens[i].children.splice(j, 1);
      } else {
        token.content = token.content.slice(endChar + options.rightDelimiter.length);
      }
    }
  }, {
    /**
     * | h1 |
     * | -- |
     * | c1 |
     *
     * {.c}
     */
    name: 'tables',
    tests: [{
      // let this token be i, such that for-loop continues at
      // next token after tokens.splice
      shift: 0,
      type: 'table_close'
    }, {
      shift: 1,
      type: 'paragraph_open'
    }, {
      shift: 2,
      type: 'inline',
      content: utils.hasDelimiters('only', options)
    }],
    transform: function transform(tokens, i) {
      var token = tokens[i + 2];
      var tableOpen = utils.getMatchingOpeningToken(tokens, i);
      var attrs = utils.getAttrs(token.content, 0, options);
      // add attributes
      utils.addAttrs(attrs, tableOpen);
      // remove <p>{.c}</p>
      tokens.splice(i + 1, 3);
    }
  }, {
    /**
     * *emphasis*{.with attrs=1}
     */
    name: 'inline attributes',
    tests: [{
      shift: 0,
      type: 'inline',
      children: [{
        shift: -1,
        nesting: -1 // closing inline tag, </em>{.a}
      }, {
        shift: 0,
        type: 'text',
        content: utils.hasDelimiters('start', options)
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var content = token.content;
      var attrs = utils.getAttrs(content, 0, options);
      var openingToken = utils.getMatchingOpeningToken(tokens[i].children, j - 1);
      utils.addAttrs(attrs, openingToken);
      token.content = content.slice(content.indexOf(options.rightDelimiter) + options.rightDelimiter.length);
    }
  }, {
    /**
     * - item
     * {.a}
     */
    name: 'list softbreak',
    tests: [{
      shift: -2,
      type: 'list_item_open'
    }, {
      shift: 0,
      type: 'inline',
      children: [{
        position: -2,
        type: 'softbreak'
      }, {
        position: -1,
        type: 'text',
        content: utils.hasDelimiters('only', options)
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var content = token.content;
      var attrs = utils.getAttrs(content, 0, options);
      var ii = i - 2;
      while (tokens[ii - 1] && tokens[ii - 1].type !== 'ordered_list_open' && tokens[ii - 1].type !== 'bullet_list_open') {
        ii--;
      }
      utils.addAttrs(attrs, tokens[ii - 1]);
      tokens[i].children = tokens[i].children.slice(0, -2);
    }
  }, {
    /**
     * - nested list
     *   - with double \n
     *   {.a} <-- apply to nested ul
     *
     * {.b} <-- apply to root <ul>
     */
    name: 'list double softbreak',
    tests: [{
      // let this token be i = 0 so that we can erase
      // the <p>{.a}</p> tokens below
      shift: 0,
      type: function type(str) {
        return str === 'bullet_list_close' || str === 'ordered_list_close';
      }
    }, {
      shift: 1,
      type: 'paragraph_open'
    }, {
      shift: 2,
      type: 'inline',
      content: utils.hasDelimiters('only', options),
      children: function children(arr) {
        return arr.length === 1;
      }
    }, {
      shift: 3,
      type: 'paragraph_close'
    }],
    transform: function transform(tokens, i) {
      var token = tokens[i + 2];
      var content = token.content;
      var attrs = utils.getAttrs(content, 0, options);
      var openingToken = utils.getMatchingOpeningToken(tokens, i);
      utils.addAttrs(attrs, openingToken);
      tokens.splice(i + 1, 3);
    }
  }, {
    /**
     * - end of {.list-item}
     */
    name: 'list item end',
    tests: [{
      shift: -2,
      type: 'list_item_open'
    }, {
      shift: 0,
      type: 'inline',
      children: [{
        position: -1,
        type: 'text',
        content: utils.hasDelimiters('end', options)
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var content = token.content;
      var attrs = utils.getAttrs(content, content.lastIndexOf(options.leftDelimiter), options);
      utils.addAttrs(attrs, tokens[i - 2]);
      var trimmed = content.slice(0, content.lastIndexOf(options.leftDelimiter));
      token.content = last(trimmed) !== ' ' ? trimmed : trimmed.slice(0, -1);
    }
  }, {
    /**
     * something with softbreak
     * {.cls}
     */
    name: '\n{.a} softbreak then curly in start',
    tests: [{
      shift: 0,
      type: 'inline',
      children: [{
        position: -2,
        type: 'softbreak'
      }, {
        position: -1,
        type: 'text',
        content: utils.hasDelimiters('only', options)
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var attrs = utils.getAttrs(token.content, 0, options);
      // find last closing tag
      var ii = i + 1;
      while (tokens[ii + 1] && tokens[ii + 1].nesting === -1) {
        ii++;
      }
      var openingToken = utils.getMatchingOpeningToken(tokens, ii);
      utils.addAttrs(attrs, openingToken);
      tokens[i].children = tokens[i].children.slice(0, -2);
    }
  }, {
    /**
     * horizontal rule --- {#id}
     */
    name: 'horizontal rule',
    tests: [{
      shift: 0,
      type: 'paragraph_open'
    }, {
      shift: 1,
      type: 'inline',
      children: function children(arr) {
        return arr.length === 1;
      },
      content: function content(str) {
        return str.match(__hr) !== null;
      }
    }, {
      shift: 2,
      type: 'paragraph_close'
    }],
    transform: function transform(tokens, i) {
      var token = tokens[i];
      token.type = 'hr';
      token.tag = 'hr';
      token.nesting = 0;
      var content = tokens[i + 1].content;
      var start = content.lastIndexOf(options.leftDelimiter);
      var attrs = utils.getAttrs(content, start, options);
      utils.addAttrs(attrs, token);
      token.markup = content;
      tokens.splice(i + 1, 2);
    }
  }, {
    /**
     * end of {.block}
     */
    name: 'end of block',
    tests: [{
      shift: 0,
      type: 'inline',
      children: [{
        position: -1,
        content: utils.hasDelimiters('end', options),
        type: function type(t) {
          return t !== 'code_inline' && t !== 'math_inline';
        }
      }]
    }],
    transform: function transform(tokens, i, j) {
      var token = tokens[i].children[j];
      var content = token.content;
      var attrs = utils.getAttrs(content, content.lastIndexOf(options.leftDelimiter), options);
      var ii = i + 1;
      do {
        if (tokens[ii] && tokens[ii].nesting === -1) {
          break;
        }
      } while (ii++ < tokens.length);
      var openingToken = utils.getMatchingOpeningToken(tokens, ii);
      utils.addAttrs(attrs, openingToken);
      var trimmed = content.slice(0, content.lastIndexOf(options.leftDelimiter));
      token.content = last(trimmed) !== ' ' ? trimmed : trimmed.slice(0, -1);
    }
  }];
};

// get last element of array or string
function last(arr) {
  return arr.slice(-1)[0];
}

},{"./utils.js":3}],3:[function(require,module,exports){
"use strict";

/**
 * parse {.class #id key=val} strings
 * @param {string} str: string to parse
 * @param {int} start: where to start parsing (including {)
 * @returns {2d array}: [['key', 'val'], ['class', 'red']]
 */
exports.getAttrs = function (str, start, options) {
  // not tab, line feed, form feed, space, solidus, greater than sign, quotation mark, apostrophe and equals sign
  var allowedKeyChars = /[^\t\n\f />"'=]/;
  var pairSeparator = ' ';
  var keySeparator = '=';
  var classChar = '.';
  var idChar = '#';
  var attrs = [];
  var key = '';
  var value = '';
  var parsingKey = true;
  var valueInsideQuotes = false;

  // read inside {}
  // start + left delimiter length to avoid beginning {
  // breaks when } is found or end of string
  for (var i = start + options.leftDelimiter.length; i < str.length; i++) {
    if (str.slice(i, i + options.rightDelimiter.length) === options.rightDelimiter) {
      if (key !== '') {
        attrs.push([key, value]);
      }
      break;
    }
    var char_ = str.charAt(i);

    // switch to reading value if equal sign
    if (char_ === keySeparator && parsingKey) {
      parsingKey = false;
      continue;
    }

    // {.class} {..css-module}
    if (char_ === classChar && key === '') {
      if (str.charAt(i + 1) === classChar) {
        key = 'css-module';
        i += 1;
      } else {
        key = 'class';
      }
      parsingKey = false;
      continue;
    }

    // {#id}
    if (char_ === idChar && key === '') {
      key = 'id';
      parsingKey = false;
      continue;
    }

    // {value="inside quotes"}
    if (char_ === '"' && value === '' && !valueInsideQuotes) {
      valueInsideQuotes = true;
      continue;
    }
    if (char_ === '"' && valueInsideQuotes) {
      valueInsideQuotes = false;
      continue;
    }

    // read next key/value pair
    if (char_ === pairSeparator && !valueInsideQuotes) {
      if (key === '') {
        // beginning or ending space: { .red } vs {.red}
        continue;
      }
      attrs.push([key, value]);
      key = '';
      value = '';
      parsingKey = true;
      continue;
    }

    // continue if character not allowed
    if (parsingKey && char_.search(allowedKeyChars) === -1) {
      continue;
    }

    // no other conditions met; append to key/value
    if (parsingKey) {
      key += char_;
      continue;
    }
    value += char_;
  }
  if (options.allowedAttributes && options.allowedAttributes.length) {
    var allowedAttributes = options.allowedAttributes;
    return attrs.filter(function (attrPair) {
      var attr = attrPair[0];
      function isAllowedAttribute(allowedAttribute) {
        return attr === allowedAttribute || allowedAttribute instanceof RegExp && allowedAttribute.test(attr);
      }
      return allowedAttributes.some(isAllowedAttribute);
    });
  }
  return attrs;
};

/**
 * add attributes from [['key', 'val']] list
 * @param {array} attrs: [['key', 'val']]
 * @param {token} token: which token to add attributes
 * @returns token
 */
exports.addAttrs = function (attrs, token) {
  for (var j = 0, l = attrs.length; j < l; ++j) {
    var key = attrs[j][0];
    if (key === 'class') {
      token.attrJoin('class', attrs[j][1]);
    } else if (key === 'css-module') {
      token.attrJoin('css-module', attrs[j][1]);
    } else {
      token.attrPush(attrs[j]);
    }
  }
  return token;
};

/**
 * Does string have properly formatted curly?
 *
 * start: '{.a} asdf'
 * end: 'asdf {.a}'
 * only: '{.a}'
 *
 * @param {string} where to expect {} curly. start, end or only.
 * @return {function(string)} Function which testes if string has curly.
 */
exports.hasDelimiters = function (where, options) {
  if (!where) {
    throw new Error('Parameter `where` not passed. Should be "start", "end" or "only".');
  }

  /**
   * @param {string} str
   * @return {boolean}
   */
  return function (str) {
    // we need minimum three chars, for example {b}
    var minCurlyLength = options.leftDelimiter.length + 1 + options.rightDelimiter.length;
    if (!str || typeof str !== 'string' || str.length < minCurlyLength) {
      return false;
    }
    function validCurlyLength(curly) {
      var isClass = curly.charAt(options.leftDelimiter.length) === '.';
      var isId = curly.charAt(options.leftDelimiter.length) === '#';
      return isClass || isId ? curly.length >= minCurlyLength + 1 : curly.length >= minCurlyLength;
    }
    var start, end, slice, nextChar;
    var rightDelimiterMinimumShift = minCurlyLength - options.rightDelimiter.length;
    switch (where) {
      case 'start':
        // first char should be {, } found in char 2 or more
        slice = str.slice(0, options.leftDelimiter.length);
        start = slice === options.leftDelimiter ? 0 : -1;
        end = start === -1 ? -1 : str.indexOf(options.rightDelimiter, rightDelimiterMinimumShift);
        // check if next character is not one of the delimiters
        nextChar = str.charAt(end + options.rightDelimiter.length);
        if (nextChar && options.rightDelimiter.indexOf(nextChar) !== -1) {
          end = -1;
        }
        break;
      case 'end':
        // last char should be }
        start = str.lastIndexOf(options.leftDelimiter);
        end = start === -1 ? -1 : str.indexOf(options.rightDelimiter, start + rightDelimiterMinimumShift);
        end = end === str.length - options.rightDelimiter.length ? end : -1;
        break;
      case 'only':
        // '{.a}'
        slice = str.slice(0, options.leftDelimiter.length);
        start = slice === options.leftDelimiter ? 0 : -1;
        slice = str.slice(str.length - options.rightDelimiter.length);
        end = slice === options.rightDelimiter ? str.length - options.rightDelimiter.length : -1;
        break;
      default:
        throw new Error("Unexpected case ".concat(where, ", expected 'start', 'end' or 'only'"));
    }
    return start !== -1 && end !== -1 && validCurlyLength(str.substring(start, end + options.rightDelimiter.length));
  };
};

/**
 * Removes last curly from string.
 */
exports.removeDelimiter = function (str, options) {
  var start = escapeRegExp(options.leftDelimiter);
  var end = escapeRegExp(options.rightDelimiter);
  var curly = new RegExp('[ \\n]?' + start + '[^' + start + end + ']+' + end + '$');
  var pos = str.search(curly);
  return pos !== -1 ? str.slice(0, pos) : str;
};

/**
 * Escapes special characters in string s such that the string
 * can be used in `new RegExp`. For example "[" becomes "\\[".
 *
 * @param {string} s Regex string.
 * @return {string} Escaped string.
 */
function escapeRegExp(s) {
  return s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');
}
exports.escapeRegExp = escapeRegExp;

/**
 * find corresponding opening block
 */
exports.getMatchingOpeningToken = function (tokens, i) {
  if (tokens[i].type === 'softbreak') {
    return false;
  }
  // non closing blocks, example img
  if (tokens[i].nesting === 0) {
    return tokens[i];
  }
  var level = tokens[i].level;
  var type = tokens[i].type.replace('_close', '_open');
  for (; i >= 0; --i) {
    if (tokens[i].type === type && tokens[i].level === level) {
      return tokens[i];
    }
  }
  return false;
};

/**
 * from https://github.com/markdown-it/markdown-it/blob/master/lib/common/utils.js
 */
var HTML_ESCAPE_TEST_RE = /[&<>"]/;
var HTML_ESCAPE_REPLACE_RE = /[&<>"]/g;
var HTML_REPLACEMENTS = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;'
};
function replaceUnsafeChar(ch) {
  return HTML_REPLACEMENTS[ch];
}
exports.escapeHtml = function (str) {
  if (HTML_ESCAPE_TEST_RE.test(str)) {
    return str.replace(HTML_ESCAPE_REPLACE_RE, replaceUnsafeChar);
  }
  return str;
};

},{}]},{},[1])(1)
});
