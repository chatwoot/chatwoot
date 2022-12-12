'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.diffStringsRaw = exports.diffStringsUnified = exports.createPatchMark = exports.printDiffLines = exports.printAnnotation = exports.countChanges = exports.hasCommonDiff = exports.printCommonLine = exports.printInsertLine = exports.printDeleteLine = void 0;

var _cleanupSemantic = require('./cleanupSemantic');

var _diffLines = require('./diffLines');

var _diffStrings = _interopRequireDefault(require('./diffStrings'));

var _getAlignedDiffs = _interopRequireDefault(require('./getAlignedDiffs'));

var _joinAlignedDiffs = require('./joinAlignedDiffs');

var _normalizeDiffOptions = require('./normalizeDiffOptions');

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const formatTrailingSpaces = (line, trailingSpaceFormatter) =>
  line.replace(/\s+$/, match => trailingSpaceFormatter(match));

const printDiffLine = (
  line,
  isFirstOrLast,
  color,
  indicator,
  trailingSpaceFormatter,
  emptyFirstOrLastLinePlaceholder
) =>
  line.length !== 0
    ? color(
        indicator + ' ' + formatTrailingSpaces(line, trailingSpaceFormatter)
      )
    : indicator !== ' '
    ? color(indicator)
    : isFirstOrLast && emptyFirstOrLastLinePlaceholder.length !== 0
    ? color(indicator + ' ' + emptyFirstOrLastLinePlaceholder)
    : '';

const printDeleteLine = (
  line,
  isFirstOrLast,
  {
    aColor,
    aIndicator,
    changeLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  }
) =>
  printDiffLine(
    line,
    isFirstOrLast,
    aColor,
    aIndicator,
    changeLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  );

exports.printDeleteLine = printDeleteLine;

const printInsertLine = (
  line,
  isFirstOrLast,
  {
    bColor,
    bIndicator,
    changeLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  }
) =>
  printDiffLine(
    line,
    isFirstOrLast,
    bColor,
    bIndicator,
    changeLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  );

exports.printInsertLine = printInsertLine;

const printCommonLine = (
  line,
  isFirstOrLast,
  {
    commonColor,
    commonIndicator,
    commonLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  }
) =>
  printDiffLine(
    line,
    isFirstOrLast,
    commonColor,
    commonIndicator,
    commonLineTrailingSpaceColor,
    emptyFirstOrLastLinePlaceholder
  );

exports.printCommonLine = printCommonLine;

const hasCommonDiff = (diffs, isMultiline) => {
  if (isMultiline) {
    // Important: Ignore common newline that was appended to multiline strings!
    const iLast = diffs.length - 1;
    return diffs.some(
      (diff, i) =>
        diff[0] === _cleanupSemantic.DIFF_EQUAL &&
        (i !== iLast || diff[1] !== '\n')
    );
  }

  return diffs.some(diff => diff[0] === _cleanupSemantic.DIFF_EQUAL);
};

exports.hasCommonDiff = hasCommonDiff;

const countChanges = diffs => {
  let a = 0;
  let b = 0;
  diffs.forEach(diff => {
    switch (diff[0]) {
      case _cleanupSemantic.DIFF_DELETE:
        a += 1;
        break;

      case _cleanupSemantic.DIFF_INSERT:
        b += 1;
        break;
    }
  });
  return {
    a,
    b
  };
};

exports.countChanges = countChanges;

const printAnnotation = (
  {
    aAnnotation,
    aColor,
    aIndicator,
    bAnnotation,
    bColor,
    bIndicator,
    includeChangeCounts,
    omitAnnotationLines
  },
  changeCounts
) => {
  if (omitAnnotationLines) {
    return '';
  }

  let aRest = '';
  let bRest = '';

  if (includeChangeCounts) {
    const aCount = String(changeCounts.a);
    const bCount = String(changeCounts.b); // Padding right aligns the ends of the annotations.

    const baAnnotationLengthDiff = bAnnotation.length - aAnnotation.length;
    const aAnnotationPadding = ' '.repeat(Math.max(0, baAnnotationLengthDiff));
    const bAnnotationPadding = ' '.repeat(Math.max(0, -baAnnotationLengthDiff)); // Padding left aligns the ends of the counts.

    const baCountLengthDiff = bCount.length - aCount.length;
    const aCountPadding = ' '.repeat(Math.max(0, baCountLengthDiff));
    const bCountPadding = ' '.repeat(Math.max(0, -baCountLengthDiff));
    aRest =
      aAnnotationPadding + '  ' + aIndicator + ' ' + aCountPadding + aCount;
    bRest =
      bAnnotationPadding + '  ' + bIndicator + ' ' + bCountPadding + bCount;
  }

  return (
    aColor(aIndicator + ' ' + aAnnotation + aRest) +
    '\n' +
    bColor(bIndicator + ' ' + bAnnotation + bRest) +
    '\n\n'
  );
};

exports.printAnnotation = printAnnotation;

const printDiffLines = (diffs, options) =>
  printAnnotation(options, countChanges(diffs)) +
  (options.expand
    ? (0, _joinAlignedDiffs.joinAlignedDiffsExpand)(diffs, options)
    : (0, _joinAlignedDiffs.joinAlignedDiffsNoExpand)(diffs, options)); // In GNU diff format, indexes are one-based instead of zero-based.

exports.printDiffLines = printDiffLines;

const createPatchMark = (aStart, aEnd, bStart, bEnd, {patchColor}) =>
  patchColor(
    `@@ -${aStart + 1},${aEnd - aStart} +${bStart + 1},${bEnd - bStart} @@`
  ); // Compare two strings character-by-character.
// Format as comparison lines in which changed substrings have inverse colors.

exports.createPatchMark = createPatchMark;

const diffStringsUnified = (a, b, options) => {
  if (a !== b && a.length !== 0 && b.length !== 0) {
    const isMultiline = a.includes('\n') || b.includes('\n'); // getAlignedDiffs assumes that a newline was appended to the strings.

    const diffs = diffStringsRaw(
      isMultiline ? a + '\n' : a,
      isMultiline ? b + '\n' : b,
      true // cleanupSemantic
    );

    if (hasCommonDiff(diffs, isMultiline)) {
      const optionsNormalized = (0, _normalizeDiffOptions.normalizeDiffOptions)(
        options
      );
      const lines = (0, _getAlignedDiffs.default)(
        diffs,
        optionsNormalized.changeColor
      );
      return printDiffLines(lines, optionsNormalized);
    }
  } // Fall back to line-by-line diff.

  return (0, _diffLines.diffLinesUnified)(
    a.split('\n'),
    b.split('\n'),
    options
  );
}; // Compare two strings character-by-character.
// Optionally clean up small common substrings, also known as chaff.

exports.diffStringsUnified = diffStringsUnified;

const diffStringsRaw = (a, b, cleanup) => {
  const diffs = (0, _diffStrings.default)(a, b);

  if (cleanup) {
    (0, _cleanupSemantic.cleanupSemantic)(diffs); // impure function
  }

  return diffs;
};

exports.diffStringsRaw = diffStringsRaw;
