import { Linter, Rule, SourceCode } from 'eslint';
export { verifyAndFix } from '../eslint/linter.js';
export { type SuggestionFilter, type FixToApplySuggestionsArgs, createFixToApplySuggestions, } from './apply-suggestions.js';
export { type FixToApplyAutoFixesArgs, createFixToApplyAutoFixes } from './apply-auto-fixes.js';
export { type FixToDisablePerFileArgs, createFixToDisablePerFile } from './disable-per-file.js';
export { type FixToDisablePerLineArgs, createFixToDisablePerLine } from './disable-per-line.js';
export { type FixToConvertErrorToWarningPerFileArgs, createFixToConvertErrorToWarningPerFile, } from './convert-error-to-warning-per-file.js';
export { type FixableMaker, type FixToMakeFixableAndFixArgs, createFixToMakeFixableAndFix, } from './make-fixable-and-fix.js';
/**
 * The type representing the additional information for the fix.
 */
export type FixContext = {
    filename: string;
    sourceCode: SourceCode;
    messages: Linter.LintMessage[];
    ruleIds: string[];
    fixer: Rule.RuleFixer;
};
//# sourceMappingURL=index.d.ts.map