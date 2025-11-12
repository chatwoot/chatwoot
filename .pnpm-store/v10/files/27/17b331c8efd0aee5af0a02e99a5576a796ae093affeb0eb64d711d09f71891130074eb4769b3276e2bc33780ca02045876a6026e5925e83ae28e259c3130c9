import { fixingSpinner } from '../cli/ora.js';
import { promptToInputDescription, promptToInputDescriptionPosition } from '../cli/prompt.js';
export async function doDisablePerLineAction(core, results, selectedRuleIds) {
    const description = await promptToInputDescription();
    let descriptionPosition;
    if (description) {
        descriptionPosition = await promptToInputDescriptionPosition();
    }
    const undo = await fixingSpinner(async () => core.disablePerLine(results, selectedRuleIds, description, descriptionPosition));
    return undo;
}
//# sourceMappingURL=disable-per-line.js.map