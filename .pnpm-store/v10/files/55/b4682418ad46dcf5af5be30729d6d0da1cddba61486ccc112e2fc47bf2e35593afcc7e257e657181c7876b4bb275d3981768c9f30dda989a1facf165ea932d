import { Remote } from 'comlink';
import { warn } from '../cli/log.js';
import { lintingSpinner } from '../cli/ora.js';
import { SerializableCore } from '../core-worker.js';
import { unique } from '../util/array.js';
import { notEmpty } from '../util/type-check.js';
import { NextScene } from './index.js';

/**
 * Run the scene to lint.
 */
export async function lint(core: Remote<SerializableCore>): Promise<NextScene> {
  const results = await lintingSpinner(async () => core.lint());
  console.log();

  const ruleIdsInResults = unique(
    results
      .flatMap((result) => result.messages)
      .flatMap((message) => message.ruleId)
      .filter(notEmpty),
  );

  if (ruleIdsInResults.length === 0) {
    console.log('💚 No error found.');
    return { name: 'exit' };
  }
  console.log(await core.formatResultSummary(results));

  const hasESLintCoreProblems = results.flatMap((result) => result.messages).some((message) => message.ruleId === null);
  if (hasESLintCoreProblems) {
    warn(
      'ESLint Core Problems are found. ' +
        'The problems cannot be fixed by eslint-interactive. ' +
        'Check the details of the problem and fix it. ' +
        'This is usually caused by the invalid eslintrc or the invalid syntax of the linted code.',
    );
    console.log(await core.formatResultDetails(results, [null]));
  }
  console.log();
  return { name: 'selectRuleIds', args: { results, ruleIdsInResults } };
}
