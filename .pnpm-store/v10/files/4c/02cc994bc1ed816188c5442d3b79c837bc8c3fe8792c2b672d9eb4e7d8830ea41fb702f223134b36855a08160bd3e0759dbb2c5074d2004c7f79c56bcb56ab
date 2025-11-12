import { ESLint } from 'eslint';
import { undoingSpinner } from '../cli/ora.js';
import { Action, promptToInputWhatToDoNext } from '../cli/prompt.js';
import { Undo } from '../core.js';
import { NextScene } from './index.js';

export type CheckResultsArgs = {
  /** The lint results of the project */
  results: ESLint.LintResult[];
  /** The rule ids that are in the `results`. */
  ruleIdsInResults: string[];
  /** The rule ids to perform the action. */
  selectedRuleIds: string[];
  /** The function to execute undo. */
  undo: Undo;
  /** The selected actions. */
  selectedAction: Action;
};

/**
 * Run the scene where a user check the fix results.
 */
export async function checkResults({
  results,
  ruleIdsInResults,
  selectedRuleIds,
  undo,
  selectedAction,
}: CheckResultsArgs): Promise<NextScene> {
  const nextStep = await promptToInputWhatToDoNext();
  if (nextStep === 'exit') return { name: 'exit' };
  if (nextStep === 'undoTheFix') {
    await undoingSpinner(async () => undo());
    return {
      name: 'selectAction',
      args: { results, ruleIdsInResults, selectedRuleIds, initialAction: selectedAction },
    };
  }
  console.log();
  console.log('─'.repeat(process.stdout.columns));
  console.log();
  return { name: 'lint' };
}
