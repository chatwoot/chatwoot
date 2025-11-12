import { fixingSpinner } from '../cli/ora.js';
export async function doFixAction(core, results, selectedRuleIds) {
    const undo = await fixingSpinner(async () => core.applyAutoFixes(results, selectedRuleIds));
    return undo;
}
//# sourceMappingURL=fix.js.map