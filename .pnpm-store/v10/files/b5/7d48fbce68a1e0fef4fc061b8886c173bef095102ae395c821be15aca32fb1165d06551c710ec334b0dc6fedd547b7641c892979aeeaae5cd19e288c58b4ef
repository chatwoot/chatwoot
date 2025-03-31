import chalk from 'chalk';
import { ESLint } from 'eslint';
import { ERROR_COLOR, FAILED_COLOR, WARNING_COLOR } from './colors.js';

function pluralize(word: string, count: number): string {
  return count > 1 ? `${word}s` : word;
}

export function formatByFiles(results: ESLint.LintResult[]): string {
  let errorCount = 0;
  let failureCount = 0;
  let passCount = 0;
  let warningCount = 0;

  results.forEach((result) => {
    const messages = result.messages;

    if (messages.length === 0) {
      passCount++;
    } else {
      failureCount++;
      warningCount += result.warningCount;
      errorCount += result.errorCount;
    }
  });

  const fileCount = passCount + failureCount;
  const problemCount = errorCount + warningCount;

  let summary = '';
  summary += `- ${fileCount} ${pluralize('file', fileCount)}`;
  summary += ' (';
  summary += `${passCount} ${pluralize('file', passCount)} passed`;
  summary += ', ';
  summary += chalk[FAILED_COLOR](`${failureCount} ${pluralize('file', failureCount)} failed`);
  summary += ') checked.\n';

  if (problemCount > 0) {
    summary += `- ${problemCount} ${pluralize('problem', problemCount)}`;
    summary += ' (';
    summary += chalk[ERROR_COLOR](`${errorCount} ${pluralize('error', errorCount)}`);
    summary += ', ';
    summary += chalk[WARNING_COLOR](`${warningCount} ${pluralize('warning', warningCount)}`);
    summary += ') found.';
  }

  return chalk.bold(summary);
}
