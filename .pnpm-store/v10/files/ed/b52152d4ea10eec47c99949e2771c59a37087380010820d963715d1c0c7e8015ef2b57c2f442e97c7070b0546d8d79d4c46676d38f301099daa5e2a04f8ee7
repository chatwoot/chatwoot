import { fixingSpinner } from '../cli/ora.js';
import { promptToInputDescription, promptToInputDescriptionPosition } from '../cli/prompt.js';
export async function doDisablePerFileAction(core, results, selectedRuleIds) {
    const description = await promptToInputDescription();
    let descriptionPosition;
    if (description) {
        descriptionPosition = await promptToInputDescriptionPosition();
    }
    const undo = await fixingSpinner(async () => core.disablePerFile(results, selectedRuleIds, description, descriptionPosition));
    return undo;
}
//# sourceMappingURL=disable-per-file.js.map