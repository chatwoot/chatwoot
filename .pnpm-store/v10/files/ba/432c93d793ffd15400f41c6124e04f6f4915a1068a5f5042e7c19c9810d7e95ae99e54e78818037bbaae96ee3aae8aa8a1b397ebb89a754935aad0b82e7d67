import { Rule, Linter } from 'eslint';
import { unique } from '../util/array.js';
import { findShebang, toInlineConfigCommentText } from '../util/eslint.js';
import { notEmpty } from '../util/type-check.js';
import { FixContext } from './index.js';

export type FixToConvertErrorToWarningPerFileArgs = {
  description?: string | undefined;
};

function generateFix(context: FixContext, description?: string): Rule.Fix | null {
  const ruleIdsToConverting = unique(
    context.messages
      // Ignore warnings
      .filter((message) => message.severity === 2)
      .map((message) => message.ruleId)
      .filter(notEmpty),
  );
  if (ruleIdsToConverting.length === 0) return null;

  const rulesRecordToConverting: Partial<Linter.RulesRecord> = Object.fromEntries(
    ruleIdsToConverting.map((ruleId) => [ruleId, 1]),
  );

  // Insert the inline config comment at the top of the file.
  // NOTE: Merging settings into an existing inline config comment is intentionally avoided
  // because of the complexity of the implementation.

  const text = `${toInlineConfigCommentText({ rulesRecord: rulesRecordToConverting, description })}\n`;

  const shebang = findShebang(context.sourceCode.text);
  // if shebang exists, insert comment after shebang
  return context.fixer.insertTextAfterRange(shebang?.range ?? [0, 0], text);
}

/**
 * Create fix to convert error to warning per file.
 */
export function createFixToConvertErrorToWarningPerFile(
  context: FixContext,
  args: FixToConvertErrorToWarningPerFileArgs,
): Rule.Fix[] {
  const fix = generateFix(context, args.description);
  return fix ? [fix] : [];
}
