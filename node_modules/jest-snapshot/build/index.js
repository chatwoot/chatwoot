'use strict';

var fs = _interopRequireWildcard(require('graceful-fs'));

var _jestMatcherUtils = require('jest-matcher-utils');

var _SnapshotResolver = require('./SnapshotResolver');

var _State = _interopRequireDefault(require('./State'));

var _plugins = require('./plugins');

var _printSnapshot = require('./printSnapshot');

var utils = _interopRequireWildcard(require('./utils'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

var Symbol = global['jest-symbol-do-not-touch'] || global.Symbol;
var Symbol = global['jest-symbol-do-not-touch'] || global.Symbol;
var jestExistsFile =
  global[Symbol.for('jest-native-exists-file')] || fs.existsSync;
const DID_NOT_THROW = 'Received function did not throw'; // same as toThrow

const NOT_SNAPSHOT_MATCHERS = `Snapshot matchers cannot be used with ${(0,
_jestMatcherUtils.BOLD_WEIGHT)('not')}`;
const INDENTATION_REGEX = /^([^\S\n]*)\S/m; // Display name in report when matcher fails same as in snapshot file,
// but with optional hint argument in bold weight.

const printSnapshotName = (concatenatedBlockNames = '', hint = '', count) => {
  const hasNames = concatenatedBlockNames.length !== 0;
  const hasHint = hint.length !== 0;
  return (
    'Snapshot name: `' +
    (hasNames ? utils.escapeBacktickString(concatenatedBlockNames) : '') +
    (hasNames && hasHint ? ': ' : '') +
    (hasHint
      ? (0, _jestMatcherUtils.BOLD_WEIGHT)(utils.escapeBacktickString(hint))
      : '') +
    ' ' +
    count +
    '`'
  );
};

function stripAddedIndentation(inlineSnapshot) {
  // Find indentation if exists.
  const match = inlineSnapshot.match(INDENTATION_REGEX);

  if (!match || !match[1]) {
    // No indentation.
    return inlineSnapshot;
  }

  const indentation = match[1];
  const lines = inlineSnapshot.split('\n');

  if (lines.length <= 2) {
    // Must be at least 3 lines.
    return inlineSnapshot;
  }

  if (lines[0].trim() !== '' || lines[lines.length - 1].trim() !== '') {
    // If not blank first and last lines, abort.
    return inlineSnapshot;
  }

  for (let i = 1; i < lines.length - 1; i++) {
    if (lines[i] !== '') {
      if (lines[i].indexOf(indentation) !== 0) {
        // All lines except first and last should either be blank or have the same
        // indent as the first line (or more). If this isn't the case we don't
        // want to touch the snapshot at all.
        return inlineSnapshot;
      }

      lines[i] = lines[i].substr(indentation.length);
    }
  } // Last line is a special case because it won't have the same indent as others
  // but may still have been given some indent to line up.

  lines[lines.length - 1] = ''; // Return inline snapshot, now at indent 0.

  inlineSnapshot = lines.join('\n');
  return inlineSnapshot;
}

const fileExists = (filePath, hasteFS) =>
  hasteFS.exists(filePath) || jestExistsFile(filePath);

const cleanup = (hasteFS, update, snapshotResolver, testPathIgnorePatterns) => {
  const pattern = '\\.' + _SnapshotResolver.EXTENSION + '$';
  const files = hasteFS.matchFiles(pattern);
  let testIgnorePatternsRegex = null;

  if (testPathIgnorePatterns && testPathIgnorePatterns.length > 0) {
    testIgnorePatternsRegex = new RegExp(testPathIgnorePatterns.join('|'));
  }

  const list = files.filter(snapshotFile => {
    const testPath = snapshotResolver.resolveTestPath(snapshotFile); // ignore snapshots of ignored tests

    if (testIgnorePatternsRegex && testIgnorePatternsRegex.test(testPath)) {
      return false;
    }

    if (!fileExists(testPath, hasteFS)) {
      if (update === 'all') {
        fs.unlinkSync(snapshotFile);
      }

      return true;
    }

    return false;
  });
  return {
    filesRemoved: list.length,
    filesRemovedList: list
  };
};

const toMatchSnapshot = function (received, propertiesOrHint, hint) {
  const matcherName = 'toMatchSnapshot';
  let properties;
  const length = arguments.length;

  if (length === 2 && typeof propertiesOrHint === 'string') {
    hint = propertiesOrHint;
  } else if (length >= 2) {
    if (typeof propertiesOrHint !== 'object' || propertiesOrHint === null) {
      const options = {
        isNot: this.isNot,
        promise: this.promise
      };
      let printedWithType = (0, _jestMatcherUtils.printWithType)(
        'Expected properties',
        propertiesOrHint,
        _printSnapshot.printExpected
      );

      if (length === 3) {
        options.secondArgument = 'hint';
        options.secondArgumentColor = _jestMatcherUtils.BOLD_WEIGHT;

        if (propertiesOrHint == null) {
          printedWithType += `\n\nTo provide a hint without properties: toMatchSnapshot('hint')`;
        }
      }

      throw new Error(
        (0, _jestMatcherUtils.matcherErrorMessage)(
          (0, _jestMatcherUtils.matcherHint)(
            matcherName,
            undefined,
            _printSnapshot.PROPERTIES_ARG,
            options
          ),
          `Expected ${(0, _jestMatcherUtils.EXPECTED_COLOR)(
            'properties'
          )} must be an object`,
          printedWithType
        )
      );
    } // Future breaking change: Snapshot hint must be a string
    // if (arguments.length === 3 && typeof hint !== 'string') {}

    properties = propertiesOrHint;
  }

  return _toMatchSnapshot({
    context: this,
    hint,
    isInline: false,
    matcherName,
    properties,
    received
  });
};

const toMatchInlineSnapshot = function (
  received,
  propertiesOrSnapshot,
  inlineSnapshot
) {
  const matcherName = 'toMatchInlineSnapshot';
  let properties;
  const length = arguments.length;

  if (length === 2 && typeof propertiesOrSnapshot === 'string') {
    inlineSnapshot = propertiesOrSnapshot;
  } else if (length >= 2) {
    const options = {
      isNot: this.isNot,
      promise: this.promise
    };

    if (length === 3) {
      options.secondArgument = _printSnapshot.SNAPSHOT_ARG;
      options.secondArgumentColor = _printSnapshot.noColor;
    }

    if (
      typeof propertiesOrSnapshot !== 'object' ||
      propertiesOrSnapshot === null
    ) {
      throw new Error(
        (0, _jestMatcherUtils.matcherErrorMessage)(
          (0, _jestMatcherUtils.matcherHint)(
            matcherName,
            undefined,
            _printSnapshot.PROPERTIES_ARG,
            options
          ),
          `Expected ${(0, _jestMatcherUtils.EXPECTED_COLOR)(
            'properties'
          )} must be an object`,
          (0, _jestMatcherUtils.printWithType)(
            'Expected properties',
            propertiesOrSnapshot,
            _printSnapshot.printExpected
          )
        )
      );
    }

    if (length === 3 && typeof inlineSnapshot !== 'string') {
      throw new Error(
        (0, _jestMatcherUtils.matcherErrorMessage)(
          (0, _jestMatcherUtils.matcherHint)(
            matcherName,
            undefined,
            _printSnapshot.PROPERTIES_ARG,
            options
          ),
          `Inline snapshot must be a string`,
          (0, _jestMatcherUtils.printWithType)(
            'Inline snapshot',
            inlineSnapshot,
            utils.serialize
          )
        )
      );
    }

    properties = propertiesOrSnapshot;
  }

  return _toMatchSnapshot({
    context: this,
    inlineSnapshot:
      inlineSnapshot !== undefined
        ? stripAddedIndentation(inlineSnapshot)
        : undefined,
    isInline: true,
    matcherName,
    properties,
    received
  });
};

const _toMatchSnapshot = config => {
  const {
    context,
    hint,
    inlineSnapshot,
    isInline,
    matcherName,
    properties
  } = config;
  let {received} = config;
  context.dontThrow && context.dontThrow();
  const {currentTestName, isNot, snapshotState} = context;

  if (isNot) {
    throw new Error(
      (0, _jestMatcherUtils.matcherErrorMessage)(
        (0, _printSnapshot.matcherHintFromConfig)(config, false),
        NOT_SNAPSHOT_MATCHERS
      )
    );
  }

  if (snapshotState == null) {
    // Because the state is the problem, this is not a matcher error.
    // Call generic stringify from jest-matcher-utils package
    // because uninitialized snapshot state does not need snapshot serializers.
    throw new Error(
      (0, _printSnapshot.matcherHintFromConfig)(config, false) +
        '\n\n' +
        `Snapshot state must be initialized` +
        '\n\n' +
        (0, _jestMatcherUtils.printWithType)(
          'Snapshot state',
          snapshotState,
          _jestMatcherUtils.stringify
        )
    );
  }

  const fullTestName =
    currentTestName && hint
      ? `${currentTestName}: ${hint}`
      : currentTestName || ''; // future BREAKING change: || hint

  if (typeof properties === 'object') {
    if (typeof received !== 'object' || received === null) {
      throw new Error(
        (0, _jestMatcherUtils.matcherErrorMessage)(
          (0, _printSnapshot.matcherHintFromConfig)(config, false),
          `${(0, _jestMatcherUtils.RECEIVED_COLOR)(
            'received'
          )} value must be an object when the matcher has ${(0,
          _jestMatcherUtils.EXPECTED_COLOR)('properties')}`,
          (0, _jestMatcherUtils.printWithType)(
            'Received',
            received,
            _printSnapshot.printReceived
          )
        )
      );
    }

    const propertyPass = context.equals(received, properties, [
      context.utils.iterableEquality,
      context.utils.subsetEquality
    ]);

    if (!propertyPass) {
      const key = snapshotState.fail(fullTestName, received);
      const matched = /(\d+)$/.exec(key);
      const count = matched === null ? 1 : Number(matched[1]);

      const message = () =>
        (0, _printSnapshot.matcherHintFromConfig)(config, false) +
        '\n\n' +
        printSnapshotName(currentTestName, hint, count) +
        '\n\n' +
        (0, _printSnapshot.printPropertiesAndReceived)(
          properties,
          received,
          snapshotState.expand
        );

      return {
        message,
        name: matcherName,
        pass: false
      };
    } else {
      received = utils.deepMerge(received, properties);
    }
  }

  const result = snapshotState.match({
    error: context.error,
    inlineSnapshot,
    isInline,
    received,
    testName: fullTestName
  });
  const {actual, count, expected, pass} = result;

  if (pass) {
    return {
      message: () => '',
      pass: true
    };
  }

  const message =
    expected === undefined
      ? () =>
          (0, _printSnapshot.matcherHintFromConfig)(config, true) +
          '\n\n' +
          printSnapshotName(currentTestName, hint, count) +
          '\n\n' +
          `New snapshot was ${(0, _jestMatcherUtils.BOLD_WEIGHT)(
            'not written'
          )}. The update flag ` +
          `must be explicitly passed to write a new snapshot.\n\n` +
          `This is likely because this test is run in a continuous integration ` +
          `(CI) environment in which snapshots are not written by default.\n\n` +
          `Received:${actual.includes('\n') ? '\n' : ' '}${(0,
          _printSnapshot.bReceivedColor)(actual)}`
      : () =>
          (0, _printSnapshot.matcherHintFromConfig)(config, true) +
          '\n\n' +
          printSnapshotName(currentTestName, hint, count) +
          '\n\n' +
          (0, _printSnapshot.printSnapshotAndReceived)(
            expected,
            actual,
            received,
            snapshotState.expand
          ); // Passing the actual and expected objects so that a custom reporter
  // could access them, for example in order to display a custom visual diff,
  // or create a different error message

  return {
    actual,
    expected,
    message,
    name: matcherName,
    pass: false
  };
};

const toThrowErrorMatchingSnapshot = function (
  received,
  hint, // because error TS1016 for hint?: string
  fromPromise
) {
  const matcherName = 'toThrowErrorMatchingSnapshot'; // Future breaking change: Snapshot hint must be a string
  // if (hint !== undefined && typeof hint !== string) {}

  return _toThrowErrorMatchingSnapshot(
    {
      context: this,
      hint,
      isInline: false,
      matcherName,
      received
    },
    fromPromise
  );
};

const toThrowErrorMatchingInlineSnapshot = function (
  received,
  inlineSnapshot,
  fromPromise
) {
  const matcherName = 'toThrowErrorMatchingInlineSnapshot';

  if (inlineSnapshot !== undefined && typeof inlineSnapshot !== 'string') {
    const options = {
      expectedColor: _printSnapshot.noColor,
      isNot: this.isNot,
      promise: this.promise
    };
    throw new Error(
      (0, _jestMatcherUtils.matcherErrorMessage)(
        (0, _jestMatcherUtils.matcherHint)(
          matcherName,
          undefined,
          _printSnapshot.SNAPSHOT_ARG,
          options
        ),
        `Inline snapshot must be a string`,
        (0, _jestMatcherUtils.printWithType)(
          'Inline snapshot',
          inlineSnapshot,
          utils.serialize
        )
      )
    );
  }

  return _toThrowErrorMatchingSnapshot(
    {
      context: this,
      inlineSnapshot:
        inlineSnapshot !== undefined
          ? stripAddedIndentation(inlineSnapshot)
          : undefined,
      isInline: true,
      matcherName,
      received
    },
    fromPromise
  );
};

const _toThrowErrorMatchingSnapshot = (config, fromPromise) => {
  const {
    context,
    hint,
    inlineSnapshot,
    isInline,
    matcherName,
    received
  } = config;
  context.dontThrow && context.dontThrow();
  const {isNot, promise} = context;

  if (!fromPromise) {
    if (typeof received !== 'function') {
      const options = {
        isNot,
        promise
      };
      throw new Error(
        (0, _jestMatcherUtils.matcherErrorMessage)(
          (0, _jestMatcherUtils.matcherHint)(
            matcherName,
            undefined,
            '',
            options
          ),
          `${(0, _jestMatcherUtils.RECEIVED_COLOR)(
            'received'
          )} value must be a function`,
          (0, _jestMatcherUtils.printWithType)(
            'Received',
            received,
            _printSnapshot.printReceived
          )
        )
      );
    }
  }

  if (isNot) {
    throw new Error(
      (0, _jestMatcherUtils.matcherErrorMessage)(
        (0, _printSnapshot.matcherHintFromConfig)(config, false),
        NOT_SNAPSHOT_MATCHERS
      )
    );
  }

  let error;

  if (fromPromise) {
    error = received;
  } else {
    try {
      received();
    } catch (e) {
      error = e;
    }
  }

  if (error === undefined) {
    // Because the received value is a function, this is not a matcher error.
    throw new Error(
      (0, _printSnapshot.matcherHintFromConfig)(config, false) +
        '\n\n' +
        DID_NOT_THROW
    );
  }

  return _toMatchSnapshot({
    context,
    hint,
    inlineSnapshot,
    isInline,
    matcherName,
    received: error.message
  });
};

const JestSnapshot = {
  EXTENSION: _SnapshotResolver.EXTENSION,
  SnapshotState: _State.default,
  addSerializer: _plugins.addSerializer,
  buildSnapshotResolver: _SnapshotResolver.buildSnapshotResolver,
  cleanup,
  getSerializers: _plugins.getSerializers,
  isSnapshotPath: _SnapshotResolver.isSnapshotPath,
  toMatchInlineSnapshot,
  toMatchSnapshot,
  toThrowErrorMatchingInlineSnapshot,
  toThrowErrorMatchingSnapshot,
  utils
};
module.exports = JestSnapshot;
