import { Linter, Rule } from 'eslint';
import { FixContext } from './index.js';

export type SuggestionFilter = (
  suggestions: Linter.LintSuggestion[],
  message: Linter.LintMessage,
  context: FixContext,
) => Linter.LintSuggestion | null | undefined;

export type FixToApplySuggestionsArgs = {
  filter: SuggestionFilter;
};

function getApplicableSuggestion(
  message: Linter.LintMessage,
  filter: SuggestionFilter,
  context: FixContext,
): Linter.LintSuggestion | null {
  if (!message.suggestions || message.suggestions.length === 0) return null;
  const suggestion = filter(message.suggestions, message, context);
  return suggestion ?? null;
}

function generateFixPerMessage(
  context: FixContext,
  filter: SuggestionFilter,
  message: Linter.LintMessage,
): Rule.Fix | null {
  const suggestion = getApplicableSuggestion(message, filter, context);
  if (!suggestion) return null;
  return suggestion.fix;
}

/**
 * Create fix to apply suggestions.
 */
export function createFixToApplySuggestions(context: FixContext, args: FixToApplySuggestionsArgs): Rule.Fix[] {
  const fixes = [];
  for (const message of context.messages) {
    const fix = generateFixPerMessage(context, args.filter, message);
    if (fix) fixes.push(fix);
  }
  return fixes;
}
