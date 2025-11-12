import { Linter, Rule } from 'eslint';
import { FixContext } from './index.js';
export type SuggestionFilter = (suggestions: Linter.LintSuggestion[], message: Linter.LintMessage, context: FixContext) => Linter.LintSuggestion | null | undefined;
export type FixToApplySuggestionsArgs = {
    filter: SuggestionFilter;
};
/**
 * Create fix to apply suggestions.
 */
export declare function createFixToApplySuggestions(context: FixContext, args: FixToApplySuggestionsArgs): Rule.Fix[];
//# sourceMappingURL=apply-suggestions.d.ts.map