import { ESLint } from 'eslint';
/**
 * The type that indicates what to do with the problems of selected rules.
 */
export type Action = 'printResultDetails' | 'applyAutoFixes' | 'disablePerLine' | 'disablePerFile' | 'convertErrorToWarningPerFile' | 'applySuggestions' | 'makeFixableAndFix' | 'reselectRules';
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
export declare function promptToInputRuleIds(ruleIdsInResults: string[]): Promise<string[]>;
/**
 * Ask the user what action they want to perform.
 * @returns The action name
 */
export declare function promptToInputAction(results: ESLint.LintResult[], selectedRuleIds: string[], initialAction?: Action): Promise<Action>;
/**
 * Ask the user how to display the lint results.
 * @returns How to display
 */
export declare function promptToInputDisplayMode(): Promise<DisplayMode>;
/**
 * Ask the user a description to leave in directive.
 * @returns The description
 */
export declare function promptToInputDescription(): Promise<string | undefined>;
/**
 * Ask the user a position of the description
 * @returns The description position
 */
export declare function promptToInputDescriptionPosition(): Promise<DescriptionPosition>;
/**
 * Ask the user what to do next.
 * @returns What to do next.
 */
export declare function promptToInputWhatToDoNext(): Promise<NextStep>;
/**
 * Ask the user if they want to reuse the filter script.
 * @returns If it reuses, `true`, if not, `false`.
 */
export declare function promptToInputReuseFilterScript(): Promise<boolean>;
/**
 * Ask the user if they want to reuse the script.
 * @returns If it reuses, `true`, if not, `false`.
 */
export declare function promptToInputReuseScript(): Promise<boolean>;
export {};
//# sourceMappingURL=prompt.d.ts.map