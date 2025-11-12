import { ESLint } from 'eslint';
import { Action } from '../cli/prompt.js';
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
export declare function checkResults({ results, ruleIdsInResults, selectedRuleIds, undo, selectedAction, }: CheckResultsArgs): Promise<NextScene>;
//# sourceMappingURL=check-results.d.ts.map