import { Remote } from 'comlink';
import { ESLint } from 'eslint';
import { SerializableCore } from '../core-worker.js';
import { NextScene } from './index.js';
export type SelectRuleIdsArgs = {
    /** The lint results of the project */
    results: ESLint.LintResult[];
    /** The rule ids that are in the `results`. */
    ruleIdsInResults: string[];
};
/**
 * Run the scene where a user select rule ids.
 */
export declare function selectRuleIds(core: Remote<SerializableCore>, { results, ruleIdsInResults }: SelectRuleIdsArgs): Promise<NextScene>;
//# sourceMappingURL=select-rule-ids.d.ts.map