// copy from: https://github.com/eslint/eslint/blob/d191bdd67214c33e65bd605e616ca7cc947fd045/lib/linter/report-translator.js
// ESLint does not export `mergeFixes`. So, I've copied the implementation.

/**
 * @fileoverview A helper that translates context.report() calls from the rule API into generic problem objects
 * @author Teddy Katz
 */

import assert from 'node:assert';
import { Rule, SourceCode } from 'eslint';

/**
 * Clones the given fix object.
 * @param {Fix|null} fix The fix to clone.
 * @returns {Fix|null} Deep cloned fix object or `null` if `null` or `undefined` was passed in.
 */
function cloneFix(fix: Rule.Fix | null | undefined): Rule.Fix | null {
  if (!fix) {
    return null;
  }

  return {
    range: [fix.range[0], fix.range[1]],
    text: fix.text,
  };
}

/**
 * Check that a fix has a valid range.
 * @param {Fix|null} fix The fix to validate.
 * @returns {void}
 */
function assertValidFix(fix: Rule.Fix | null): void {
  if (fix) {
    assert(
      fix.range && typeof fix.range[0] === 'number' && typeof fix.range[1] === 'number',
      `Fix has invalid range: ${JSON.stringify(fix, null, 2)}`,
    );
  }
}

/**
 * Compares items in a fixes array by range.
 * @param {Fix} a The first message.
 * @param {Fix} b The second message.
 * @returns {int} -1 if a comes before b, 1 if a comes after b, 0 if equal.
 * @private
 */
function compareFixesByRange(a: Rule.Fix, b: Rule.Fix): number {
  return a.range[0] - b.range[0] || a.range[1] - b.range[1];
}

/**
 * Merges the given fixes array into one.
 * @param {Fix[]} fixes The fixes to merge.
 * @param {SourceCode} sourceCode The source code object to get the text between fixes.
 * @returns {{text: string, range: number[]}} The merged fixes
 */
export function mergeFixes(fixes: Rule.Fix[], sourceCode: SourceCode): Rule.Fix | null {
  for (const fix of fixes) {
    assertValidFix(fix);
  }

  if (fixes.length === 0) {
    return null;
  }
  if (fixes.length === 1) {
    return cloneFix(fixes[0]);
  }

  fixes.sort(compareFixesByRange);

  const originalText = sourceCode.text;
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const start = fixes[0]!.range[0];
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const end = fixes[fixes.length - 1]!.range[1];
  let text = '';
  let lastPos = Number.MIN_SAFE_INTEGER;

  for (const fix of fixes) {
    assert(fix.range[0] >= lastPos, 'Fix objects must not be overlapped in a report.');

    if (fix.range[0] >= 0) {
      text += originalText.slice(Math.max(0, start, lastPos), fix.range[0]);
    }
    text += fix.text;
    lastPos = fix.range[1];
  }
  text += originalText.slice(Math.max(0, start, lastPos), end);

  return { range: [start, end], text };
}
