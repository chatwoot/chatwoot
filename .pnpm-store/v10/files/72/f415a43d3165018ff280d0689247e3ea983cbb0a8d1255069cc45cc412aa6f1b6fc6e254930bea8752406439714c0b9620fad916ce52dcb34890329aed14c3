import { fixingSpinner } from '../cli/ora.js';
import { promptToInputDescription } from '../cli/prompt.js';
export async function doConvertErrorToWarningPerFileAction(core, results, selectedRuleIds) {
    const description = await promptToInputDescription();
    const undo = await fixingSpinner(async () => core.convertErrorToWarningPerFile(results, selectedRuleIds, description));
    return undo;
}
//# sourceMappingURL=convert-error-to-warning-per-file.js.map