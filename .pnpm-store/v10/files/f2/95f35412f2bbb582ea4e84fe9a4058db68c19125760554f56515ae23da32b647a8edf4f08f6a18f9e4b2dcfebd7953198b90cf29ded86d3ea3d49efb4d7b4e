import { ESLint } from 'eslint';
import { formatByFiles } from './format-by-files.js';
import { formatByRules } from './format-by-rules.js';

export { takeRuleStatistics, type RuleStatistic } from './take-rule-statistics.js';

export function format(results: ESLint.LintResult[], data?: ESLint.LintResultData): string {
  return `${formatByFiles(results)}\n${formatByRules(results, data)}`;
}
