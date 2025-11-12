import { Rule, SourceCode } from 'eslint';
import { DescriptionPosition } from 'src/cli/prompt.js';
import { mergeFixes } from '../eslint/report-translator.js';
import { unique } from '../util/array.js';
import {
  DisableComment,
  findShebang,
  parseDisableComment,
  insertDescriptionCommentStatementBeforeLine,
  insertDisableCommentStatementBeforeLine,
  mergeDescription,
  mergeRuleIds,
  updateDisableComment,
} from '../util/eslint.js';
import { notEmpty } from '../util/type-check.js';
import { FixContext } from './index.js';

export type FixToDisablePerFileArgs = {
  description?: string | undefined;
  descriptionPosition?: DescriptionPosition | undefined;
};

function findDisableCommentPerFile(sourceCode: SourceCode): DisableComment | undefined {
  const commentsInFile = sourceCode.getAllComments();
  return commentsInFile.map(parseDisableComment).find((comment) => comment?.scope === 'file');
}

function generateFix(
  context: FixContext,
  description: string | undefined,
  descriptionPosition: DescriptionPosition | undefined,
): Rule.Fix | null {
  const { fixer, sourceCode } = context;

  const ruleIdsToDisable = unique(context.messages.map((message) => message.ruleId).filter(notEmpty));
  if (ruleIdsToDisable.length === 0) return null;

  const disableCommentPerFile = findDisableCommentPerFile(sourceCode);

  // if shebang exists, insert comment after shebang
  const shebang = findShebang(context.sourceCode.text);
  const lineToInsert =
    disableCommentPerFile ? disableCommentPerFile.loc.start.line
    : shebang ? sourceCode.getLocFromIndex(shebang.range[0]).line + 1
    : 1;

  const fixes: Rule.Fix[] = [];
  const isPreviousLine = description !== undefined && descriptionPosition === 'previousLine';

  if (isPreviousLine) {
    fixes.push(
      insertDescriptionCommentStatementBeforeLine({
        fixer,
        sourceCode,
        line: lineToInsert,
        column: 0,
        description,
      }),
    );
  }

  if (disableCommentPerFile) {
    fixes.push(
      updateDisableComment({
        fixer,
        disableComment: disableCommentPerFile,
        newRules: mergeRuleIds(disableCommentPerFile.ruleIds, ruleIdsToDisable),
        newDescription:
          isPreviousLine ?
            disableCommentPerFile.description
          : mergeDescription(disableCommentPerFile.description, description),
      }),
    );
  } else {
    fixes.push(
      insertDisableCommentStatementBeforeLine({
        fixer,
        sourceCode,
        line: lineToInsert,
        column: 0,
        scope: 'file',
        ruleIds: ruleIdsToDisable,
        description: isPreviousLine ? undefined : description,
      }),
    );
  }
  return mergeFixes(fixes, context.sourceCode);
}

/**
 * Create fix to add disable comment per file.
 */
export function createFixToDisablePerFile(context: FixContext, args: FixToDisablePerFileArgs): Rule.Fix[] {
  const fix = generateFix(context, args.description, args.descriptionPosition);
  if (fix) return [fix];
  return [];
}
