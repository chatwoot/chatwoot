import { undoingSpinner } from '../cli/ora.js';
import { promptToInputWhatToDoNext } from '../cli/prompt.js';
/**
 * Run the scene where a user check the fix results.
 */
export async function checkResults({ results, ruleIdsInResults, selectedRuleIds, undo, selectedAction, }) {
    const nextStep = await promptToInputWhatToDoNext();
    if (nextStep === 'exit')
        return { name: 'exit' };
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
//# sourceMappingURL=check-results.js.map