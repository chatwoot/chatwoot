import { CheckResultsArgs } from './check-results.js';
import { selectAction, type SelectActionArgs } from './select-action.js';
import { selectRuleIds, type SelectRuleIdsArgs } from './select-rule-ids.js';

export { selectAction, type SelectActionArgs, selectRuleIds, type SelectRuleIdsArgs };
export { lint } from './lint.js';
export { checkResults } from './check-results.js';

/**
 * The return type when calling a scene function.
 * Indicates which scene to jump to next.
 */
export type NextScene =
  | { name: 'lint' }
  | { name: 'selectRuleIds'; args: SelectRuleIdsArgs }
  | { name: 'selectAction'; args: SelectActionArgs }
  | { name: 'checkResults'; args: CheckResultsArgs }
  | { name: 'exit' };
