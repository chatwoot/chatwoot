/* istanbul ignore file */
import enquirer from 'enquirer';
import { takeRuleStatistics } from '../formatter/index.js';
const { prompt } = enquirer;
// When combined with worker, for some reason the enquirer grabs the SIGINT and the process continues to survive.
// Therefore, the process is explicitly terminated.
// eslint-disable-next-line n/no-process-exit
const onCancel = () => process.exit();
/**
 * Ask the user for the rule ids to which they want to apply the action.
 * @param ruleIdsInResults The rule ids that are in the lint results.
 * @returns The rule ids
 */
export async function promptToInputRuleIds(ruleIdsInResults) {
    const { ruleIds } = await prompt([
        {
            name: 'ruleIds',
            type: 'multiselect',
            message: 'Which rules would you like to apply action?',
            // @ts-expect-error
            hint: 'Select all you want with <space> key.',
            choices: ruleIdsInResults,
            validate(value) {
                return value.length === 0 ? `Select at least one rule with <space> key.` : true;
            },
            onCancel,
        },
    ]);
    return ruleIds;
}
/**
 * Ask the user what action they want to perform.
 * @returns The action name
 */
export async function promptToInputAction(results, selectedRuleIds, initialAction) {
    const ruleStatistics = takeRuleStatistics(results).filter((ruleStatistic) => selectedRuleIds.includes(ruleStatistic.ruleId));
    const foldedStatistics = ruleStatistics.reduce((a, b) => ({
        isFixableCount: a.isFixableCount + b.isFixableCount,
        hasSuggestionsCount: a.hasSuggestionsCount + b.hasSuggestionsCount,
    }), { isFixableCount: 0, hasSuggestionsCount: 0 });
    const choices = [
        { name: 'printResultDetails', message: '🔎 Display details of lint results' },
        { name: 'applyAutoFixes', message: '🔧 Run `eslint --fix`', disabled: foldedStatistics.isFixableCount === 0 },
        { name: 'disablePerLine', message: '🔧 Disable per line' },
        { name: 'disablePerFile', message: '🔧 Disable per file' },
        { name: 'convertErrorToWarningPerFile', message: '🔧 Convert error to warning per file' },
        {
            name: 'applySuggestions',
            message: '🔧 Apply suggestions (experimental, for experts)',
            disabled: foldedStatistics.hasSuggestionsCount === 0,
        },
        {
            name: 'makeFixableAndFix',
            message: '🔧 Make forcibly fixable and run `eslint --fix` (experimental, for experts)',
        },
        { name: 'reselectRules', message: '↩️  Reselect rules' },
    ];
    const { action } = await prompt([
        {
            name: 'action',
            type: 'select',
            message: 'Which action do you want to do?',
            choices,
            initial: choices.findIndex((choice) => choice.name === initialAction) ?? 0,
            onCancel,
        },
    ]);
    return action;
}
/**
 * Ask the user how to display the lint results.
 * @returns How to display
 */
export async function promptToInputDisplayMode() {
    const { displayMode } = await prompt([
        {
            name: 'displayMode',
            type: 'select',
            message: 'In what way are the details displayed?',
            choices: [
                { name: 'printInTerminal', message: '🖨  Print in terminal' },
                { name: 'printInTerminalWithPager', message: '↕️  Print in terminal with pager' },
                { name: 'writeToFile', message: '📝 Write to file' },
            ],
            onCancel,
        },
    ]);
    return displayMode;
}
/**
 * Ask the user a description to leave in directive.
 * @returns The description
 */
export async function promptToInputDescription() {
    const { description } = await prompt([
        {
            name: 'description',
            type: 'input',
            message: 'Leave a code comment with your reason for fixing (Optional)',
            onCancel,
        },
    ]);
    return description === '' ? undefined : description;
}
/**
 * Ask the user a position of the description
 * @returns The description position
 */
export async function promptToInputDescriptionPosition() {
    const { descriptionPosition } = await prompt([
        {
            name: 'descriptionPosition',
            type: 'select',
            message: 'Where would you like to position the code comment?',
            choices: [
                { name: 'sameLine', message: "Same Line - Place on the same line as the eslint's disable comment." },
                { name: 'previousLine', message: "Previous Line - Place on the line before the eslint's disable comment." },
            ],
            onCancel,
        },
    ]);
    return descriptionPosition;
}
/**
 * Ask the user what to do next.
 * @returns What to do next.
 */
export async function promptToInputWhatToDoNext() {
    const { nextStep } = await prompt([
        {
            name: 'nextStep',
            type: 'select',
            message: "What's the next step?",
            choices: [
                { name: 'fixOtherRules', message: '🔧 Fix other rules' },
                { name: 'undoTheFix', message: '↩️  Undo the fix' },
                { name: 'exit', message: '💚 Exit' },
            ],
            onCancel,
        },
    ]);
    return nextStep;
}
/**
 * Ask the user if they want to reuse the filter script.
 * @returns If it reuses, `true`, if not, `false`.
 */
export async function promptToInputReuseFilterScript() {
    const { reuseFilterScript } = await prompt([
        {
            name: 'reuseFilterScript',
            type: 'confirm',
            message: 'Do you want to reuse a previously edited filter script?',
            initial: true,
            onCancel,
        },
    ]);
    return reuseFilterScript;
}
/**
 * Ask the user if they want to reuse the script.
 * @returns If it reuses, `true`, if not, `false`.
 */
export async function promptToInputReuseScript() {
    const { reuseScript } = await prompt([
        {
            name: 'reuseScript',
            type: 'confirm',
            message: 'Do you want to reuse a previously edited script?',
            initial: true,
            onCancel,
        },
    ]);
    return reuseScript;
}
//# sourceMappingURL=prompt.js.map