import { doApplySuggestionsAction, doConvertErrorToWarningPerFileAction, doDisablePerFileAction, doDisablePerLineAction, doFixAction, doMakeFixableAndFixAction, doPrintResultDetailsAction, } from '../action/index.js';
import { promptToInputAction } from '../cli/prompt.js';
import { unreachable } from '../util/type-check.js';
/**
 * Run the scene where a user select the action to be performed for the problems of selected rules.
 */
export async function selectAction(core, { results, ruleIdsInResults, selectedRuleIds, initialAction }) {
    const selectedAction = await promptToInputAction(results, selectedRuleIds, initialAction);
    const selectRuleIdsScene = { name: 'selectRuleIds', args: { results, ruleIdsInResults } };
    const selectActionScene = { name: 'selectAction', args: { results, ruleIdsInResults, selectedRuleIds } };
    function createCheckResultsScene(undo) {
        return {
            name: 'checkResults',
            args: { results, ruleIdsInResults, selectedRuleIds, undo, selectedAction },
        };
    }
    if (selectedAction === 'reselectRules')
        return selectRuleIdsScene;
    if (selectedAction === 'printResultDetails') {
        await doPrintResultDetailsAction(core, results, selectedRuleIds);
        return selectActionScene;
    }
    else if (selectedAction === 'applyAutoFixes') {
        const undo = await doFixAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    else if (selectedAction === 'disablePerLine') {
        const undo = await doDisablePerLineAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    else if (selectedAction === 'disablePerFile') {
        const undo = await doDisablePerFileAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    else if (selectedAction === 'convertErrorToWarningPerFile') {
        const undo = await doConvertErrorToWarningPerFileAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    else if (selectedAction === 'applySuggestions') {
        const undo = await doApplySuggestionsAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    else if (selectedAction === 'makeFixableAndFix') {
        const undo = await doMakeFixableAndFixAction(core, results, selectedRuleIds);
        return createCheckResultsScene(undo);
    }
    // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
    return unreachable(`unknown action: ${selectedAction}`);
}
//# sourceMappingURL=select-action.js.map