import { Remote } from 'comlink';
import { ESLint } from 'eslint';
import { Action } from '../cli/prompt.js';
import { SerializableCore } from '../core-worker.js';
import { NextScene } from './index.js';
export type SelectActionArgs = {
    /** The lint results of the project */
    results: ESLint.LintResult[];
    /** The rule ids that are in the `results`. */
    ruleIdsInResults: string[];
    /** The rule ids to perform the action. */
    selectedRuleIds: string[];
    /** The action to be initially selected. */
    initialAction?: Action;
};
/**
 * Run the scene where a user select the action to be performed for the problems of selected rules.
 */
export declare function selectAction(core: Remote<SerializableCore>, { results, ruleIdsInResults, selectedRuleIds, initialAction }: SelectActionArgs): Promise<NextScene>;
//# sourceMappingURL=select-action.d.ts.map