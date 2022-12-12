'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
Object.defineProperty(exports, 'DiffOptions', {
  enumerable: true,
  get: function get() {
    return _jestDiff.DiffOptions;
  }
});
exports.matcherHint = exports.matcherErrorMessage = exports.getLabelPrinter = exports.pluralize = exports.diff = exports.ensureExpectedIsNonNegativeInteger = exports.ensureNumbers = exports.ensureExpectedIsNumber = exports.ensureActualIsNumber = exports.ensureNoExpected = exports.printWithType = exports.printExpected = exports.printReceived = exports.highlightTrailingWhitespace = exports.stringify = exports.SUGGEST_TO_CONTAIN_EQUAL = exports.DIM_COLOR = exports.BOLD_WEIGHT = exports.INVERTED_COLOR = exports.RECEIVED_COLOR = exports.EXPECTED_COLOR = void 0;

var _chalk = _interopRequireDefault(require('chalk'));

var _jestDiff = _interopRequireWildcard(require('jest-diff'));

var _jestGetType = _interopRequireDefault(require('jest-get-type'));

var _prettyFormat = _interopRequireDefault(require('pretty-format'));

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  } else {
    var newObj = {};
    if (obj != null) {
      for (var key in obj) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
          var desc =
            Object.defineProperty && Object.getOwnPropertyDescriptor
              ? Object.getOwnPropertyDescriptor(obj, key)
              : {};
          if (desc.get || desc.set) {
            Object.defineProperty(newObj, key, desc);
          } else {
            newObj[key] = obj[key];
          }
        }
      }
    }
    newObj.default = obj;
    return newObj;
  }
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const _prettyFormat$plugins = _prettyFormat.default.plugins,
  AsymmetricMatcher = _prettyFormat$plugins.AsymmetricMatcher,
  DOMCollection = _prettyFormat$plugins.DOMCollection,
  DOMElement = _prettyFormat$plugins.DOMElement,
  Immutable = _prettyFormat$plugins.Immutable,
  ReactElement = _prettyFormat$plugins.ReactElement,
  ReactTestComponent = _prettyFormat$plugins.ReactTestComponent;
const PLUGINS = [
  ReactTestComponent,
  ReactElement,
  DOMElement,
  DOMCollection,
  Immutable,
  AsymmetricMatcher
];
const EXPECTED_COLOR = _chalk.default.green;
exports.EXPECTED_COLOR = EXPECTED_COLOR;
const RECEIVED_COLOR = _chalk.default.red;
exports.RECEIVED_COLOR = RECEIVED_COLOR;
const INVERTED_COLOR = _chalk.default.inverse;
exports.INVERTED_COLOR = INVERTED_COLOR;
const BOLD_WEIGHT = _chalk.default.bold;
exports.BOLD_WEIGHT = BOLD_WEIGHT;
const DIM_COLOR = _chalk.default.dim;
exports.DIM_COLOR = DIM_COLOR;
const NUMBERS = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen'
];

const SUGGEST_TO_CONTAIN_EQUAL = _chalk.default.dim(
  'Looks like you wanted to test for object/array equality with the stricter `toContain` matcher. You probably need to use `toContainEqual` instead.'
);

exports.SUGGEST_TO_CONTAIN_EQUAL = SUGGEST_TO_CONTAIN_EQUAL;

const stringify = (object, maxDepth = 10) => {
  const MAX_LENGTH = 10000;
  let result;

  try {
    result = (0, _prettyFormat.default)(object, {
      maxDepth,
      min: true,
      plugins: PLUGINS
    });
  } catch (e) {
    result = (0, _prettyFormat.default)(object, {
      callToJSON: false,
      maxDepth,
      min: true,
      plugins: PLUGINS
    });
  }

  return result.length >= MAX_LENGTH && maxDepth > 1
    ? stringify(object, Math.floor(maxDepth / 2))
    : result;
};

exports.stringify = stringify;

const highlightTrailingWhitespace = text =>
  text.replace(/\s+$/gm, _chalk.default.inverse('$&'));

exports.highlightTrailingWhitespace = highlightTrailingWhitespace;

const printReceived = object =>
  RECEIVED_COLOR(highlightTrailingWhitespace(stringify(object)));

exports.printReceived = printReceived;

const printExpected = value =>
  EXPECTED_COLOR(highlightTrailingWhitespace(stringify(value)));

exports.printExpected = printExpected;

const printWithType = (
  name,
  value,
  print // printExpected or printReceived
) => {
  const type = (0, _jestGetType.default)(value);
  const hasType =
    type !== 'null' && type !== 'undefined'
      ? `${name} has type:  ${type}\n`
      : '';
  const hasValue = `${name} has value: ${print(value)}`;
  return hasType + hasValue;
};

exports.printWithType = printWithType;

const ensureNoExpected = (expected, matcherName, options) => {
  if (typeof expected !== 'undefined') {
    // Prepend maybe not only for backward compatibility.
    const matcherString = (options ? '' : '[.not]') + matcherName;
    throw new Error(
      matcherErrorMessage(
        matcherHint(matcherString, undefined, '', options), // Because expected is omitted in hint above,
        'this matcher must not have an expected argument',
        printWithType('Expected', expected, printExpected)
      )
    );
  }
};

exports.ensureNoExpected = ensureNoExpected;

const ensureActualIsNumber = (actual, matcherName, options) => {
  if (typeof actual !== 'number') {
    // Prepend maybe not only for backward compatibility.
    const matcherString = (options ? '' : '[.not]') + matcherName;
    throw new Error(
      matcherErrorMessage(
        matcherHint(matcherString, undefined, undefined, options),
        `${RECEIVED_COLOR('received')} value must be a number`,
        printWithType('Received', actual, printReceived)
      )
    );
  }
};

exports.ensureActualIsNumber = ensureActualIsNumber;

const ensureExpectedIsNumber = (expected, matcherName, options) => {
  if (typeof expected !== 'number') {
    // Prepend maybe not only for backward compatibility.
    const matcherString = (options ? '' : '[.not]') + matcherName;
    throw new Error(
      matcherErrorMessage(
        matcherHint(matcherString, undefined, undefined, options),
        `${EXPECTED_COLOR('expected')} value must be a number`,
        printWithType('Expected', expected, printExpected)
      )
    );
  }
};

exports.ensureExpectedIsNumber = ensureExpectedIsNumber;

const ensureNumbers = (actual, expected, matcherName, options) => {
  ensureActualIsNumber(actual, matcherName, options);
  ensureExpectedIsNumber(expected, matcherName, options);
};

exports.ensureNumbers = ensureNumbers;

const ensureExpectedIsNonNegativeInteger = (expected, matcherName, options) => {
  if (
    typeof expected !== 'number' ||
    !Number.isSafeInteger(expected) ||
    expected < 0
  ) {
    // Prepend maybe not only for backward compatibility.
    const matcherString = (options ? '' : '[.not]') + matcherName;
    throw new Error(
      matcherErrorMessage(
        matcherHint(matcherString, undefined, undefined, options),
        `${EXPECTED_COLOR('expected')} value must be a non-negative integer`,
        printWithType('Expected', expected, printExpected)
      )
    );
  }
}; // Sometimes, e.g. when comparing two numbers, the output from jest-diff
// does not contain more information than the `Expected:` / `Received:` already gives.
// In those cases, we do not print a diff to make the output shorter and not redundant.

exports.ensureExpectedIsNonNegativeInteger = ensureExpectedIsNonNegativeInteger;

const shouldPrintDiff = (actual, expected) => {
  if (typeof actual === 'number' && typeof expected === 'number') {
    return false;
  }

  if (typeof actual === 'boolean' && typeof expected === 'boolean') {
    return false;
  }

  return true;
};

const diff = (a, b, options) =>
  shouldPrintDiff(a, b) ? (0, _jestDiff.default)(a, b, options) : null;

exports.diff = diff;

const pluralize = (word, count) =>
  (NUMBERS[count] || count) + ' ' + word + (count === 1 ? '' : 's'); // To display lines of labeled values as two columns with monospace alignment:
// given the strings which will describe the values,
// return function which given each string, returns the label:
// string, colon, space, and enough padding spaces to align the value.

exports.pluralize = pluralize;

const getLabelPrinter = (...strings) => {
  const maxLength = strings.reduce(
    (max, string) => (string.length > max ? string.length : max),
    0
  );
  return string => `${string}: ${' '.repeat(maxLength - string.length)}`;
};

exports.getLabelPrinter = getLabelPrinter;

const matcherErrorMessage = (
  hint,
  generic,
  specific // incorrect value returned from call to printWithType
) =>
  `${hint}\n\n${_chalk.default.bold(
    'Matcher error'
  )}: ${generic}\n\n${specific}`; // Display assertion for the report when a test fails.
// New format: rejects/resolves, not, and matcher name have black color
// Old format: matcher name has dim color

exports.matcherErrorMessage = matcherErrorMessage;

const matcherHint = (
  matcherName,
  received = 'received',
  expected = 'expected',
  options = {}
) => {
  const _options$comment = options.comment,
    comment = _options$comment === void 0 ? '' : _options$comment,
    _options$isDirectExpe = options.isDirectExpectCall,
    isDirectExpectCall =
      _options$isDirectExpe === void 0 ? false : _options$isDirectExpe,
    _options$isNot = options.isNot,
    isNot = _options$isNot === void 0 ? false : _options$isNot,
    _options$promise = options.promise,
    promise = _options$promise === void 0 ? '' : _options$promise,
    _options$secondArgume = options.secondArgument,
    secondArgument =
      _options$secondArgume === void 0 ? '' : _options$secondArgume;
  let hint = '';
  let dimString = 'expect'; // concatenate adjacent dim substrings

  if (!isDirectExpectCall && received !== '') {
    hint += DIM_COLOR(dimString + '(') + RECEIVED_COLOR(received);
    dimString = ')';
  }

  if (promise !== '') {
    hint += DIM_COLOR(dimString + '.') + promise;
    dimString = '';
  }

  if (isNot) {
    hint += DIM_COLOR(dimString + '.') + 'not';
    dimString = '';
  }

  if (matcherName.includes('.')) {
    // Old format: for backward compatibility,
    // especially without promise or isNot options
    dimString += matcherName;
  } else {
    // New format: omit period from matcherName arg
    hint += DIM_COLOR(dimString + '.') + matcherName;
    dimString = '';
  }

  if (expected === '') {
    dimString += '()';
  } else {
    hint += DIM_COLOR(dimString + '(') + EXPECTED_COLOR(expected);

    if (secondArgument) {
      hint += DIM_COLOR(', ') + EXPECTED_COLOR(secondArgument);
    }

    dimString = ')';
  }

  if (comment !== '') {
    dimString += ' // ' + comment;
  }

  if (dimString !== '') {
    hint += DIM_COLOR(dimString);
  }

  return hint;
};

exports.matcherHint = matcherHint;
