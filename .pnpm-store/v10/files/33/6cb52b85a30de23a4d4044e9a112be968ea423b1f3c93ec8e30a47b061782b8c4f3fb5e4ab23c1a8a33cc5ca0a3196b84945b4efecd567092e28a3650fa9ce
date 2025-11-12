import { promptToInputRuleIds } from '../cli/prompt.js';
import { selectAction } from './select-action.js';
/**
 * Run the scene where a user select rule ids.
 */
export async function selectRuleIds(core, { results, ruleIdsInResults }) {
    const selectedRuleIds = await promptToInputRuleIds(ruleIdsInResults);
    return selectAction(core, { results, ruleIdsInResults, selectedRuleIds });
}
//# sourceMappingURL=select-rule-ids.js.map