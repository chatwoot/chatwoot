/* istanbul ignore file */

import enquirer from 'enquirer';
import { ESLint } from 'eslint';
import { takeRuleStatistics } from '../formatter/index.js';

const { prompt } = enquirer;

// When combined with worker, for some reason the enquirer grabs the SIGINT and the process continues to survive.
// Therefore, the process is explicitly terminated.
// eslint-disable-next-line n/no-process-exit
const onCancel = () => process.exit();

/**
 * The type that indicates what to do with the problems of selected rules.
 */
export type Action =
  | 'printResultDetails'
  | 'applyAutoFixes'
  | 'disablePerLine'
  | 'disablePerFile'
  | 'convertErrorToWarningPerFile'
  | 'applySuggestions'
  | 'makeFixableAndFix'
  | 'reselectRules';

/**
 * The type representing how to display the lint results.
 *
 * `printInTerminal` means to print the lint results in the terminal.
 * `printInTerminalWithPager` means to print the lint results in the terminal with a pager (e.g. `less`).
 * `writeToFile` means to write the lint results to a file.
 */
type DisplayMode = 'printInTerminal' | 'printInTerminalWithPager' | 'writeToFile';

/**
 * The type that represents what to do next.
 */
type NextStep = 'fixOtherRules' | 'exit' | 'undoTheFix';

export type DescriptionPosition = 'sameLine' | 'previousLine';

/**
 * Ask the user for the rule ids to which they want to apply the action.
 * @param ruleIdsInResults The rule ids that are in the lint results.
 * @returns The rule ids
 */
export async function promptToInputRuleIds(ruleIdsInResults: string[]): Promise<string[]> {
  const { ruleIds } = await prompt<{ ruleIds: string[] }>([
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
export async function promptToInputAction(
  results: ESLint.LintResult[],
  selectedRuleIds: string[],
  initialAction?: Action,
): Promise<Action> {
  const ruleStatistics = takeRuleStatistics(results).filter((ruleStatistic) =>
    selectedRuleIds.includes(ruleStatistic.ruleId),
  );
  const foldedStatistics = ruleStatistics.reduce(
    (a, b) => ({
      isFixableCount: a.isFixableCount + b.isFixableCount,
      hasSuggestionsCount: a.hasSuggestionsCount + b.hasSuggestionsCount,
    }),
    { isFixableCount: 0, hasSuggestionsCount: 0 },
  );

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

  const { action } = await prompt<{
    action: Action;
  }>([
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
export async function promptToInputDisplayMode(): Promise<DisplayMode> {
  const { displayMode } = await prompt<{
    displayMode: DisplayMode;
  }>([
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
export async function promptToInputDescription(): Promise<string | undefined> {
  const { description } = await prompt<{
    description: string;
  }>([
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
export async function promptToInputDescriptionPosition(): Promise<DescriptionPosition> {
  const { descriptionPosition } = await prompt<{
    descriptionPosition: DescriptionPosition;
  }>([
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
export async function promptToInputWhatToDoNext(): Promise<NextStep> {
  const { nextStep } = await prompt<{ nextStep: NextStep }>([
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
export async function promptToInputReuseFilterScript(): Promise<boolean> {
  const { reuseFilterScript } = await prompt<{ reuseFilterScript: boolean }>([
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
export async function promptToInputReuseScript(): Promise<boolean> {
  const { reuseScript } = await prompt<{ reuseScript: boolean }>([
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
