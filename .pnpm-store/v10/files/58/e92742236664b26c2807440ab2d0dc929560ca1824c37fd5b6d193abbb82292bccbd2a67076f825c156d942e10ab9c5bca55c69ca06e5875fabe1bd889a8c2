import { ESLint } from 'eslint';
import { DescriptionPosition } from './cli/prompt.js';
import { Config, NormalizedConfig } from './config.js';
import { FixableMaker, SuggestionFilter } from './fix/index.js';
export type Undo = () => Promise<void>;
/**
 * The core of eslint-interactive.
 * It uses ESLint's Node.js API to output a summary of problems, fix problems, apply suggestions, etc.
 */
export declare class Core {
    readonly config: NormalizedConfig;
    readonly eslint: ESLint;
    constructor(config: Config);
    /**
     * Lint project.
     * @returns The results of linting
     */
    lint(): Promise<ESLint.LintResult[]>;
    /**
     * Returns summary of lint results.
     * @param results The lint results of the project to print summary
     */
    formatResultSummary(results: ESLint.LintResult[]): string;
    /**
     * Returns details of lint results.
     * @param results The lint results of the project to print summary
     * @param ruleIds The rule ids to print details
     */
    formatResultDetails(results: ESLint.LintResult[], ruleIds: (string | null)[]): Promise<string>;
    /**
     * Run `eslint --fix`.
     * @param ruleIds The rule ids to fix
     */
    applyAutoFixes(results: ESLint.LintResult[], ruleIds: string[]): Promise<Undo>;
    /**
     * Add disable comments per line.
     * @param results The lint results of the project to add disable comments
     * @param ruleIds The rule ids to add disable comments
     * @param description The description of the disable comments
     * @param descriptionPosition The position of the description
     */
    disablePerLine(results: ESLint.LintResult[], ruleIds: string[], description?: string, descriptionPosition?: DescriptionPosition): Promise<Undo>;
    /**
     * Add disable comments per file.
     * @param results The lint results of the project to add disable comments
     * @param ruleIds The rule ids to add disable comments
     * @param description The description of the disable comments
     * @param descriptionPosition The position of the description
     */
    disablePerFile(results: ESLint.LintResult[], ruleIds: string[], description?: string, descriptionPosition?: DescriptionPosition): Promise<Undo>;
    /**
     * Convert error to warning per file.
     * @param results The lint results of the project to convert
     * @param ruleIds The rule ids to convert
     * @param description The comment explaining the reason for converting
     */
    convertErrorToWarningPerFile(results: ESLint.LintResult[], ruleIds: string[], description?: string): Promise<Undo>;
    /**
     * Apply suggestions.
     * @param results The lint results of the project to apply suggestions
     * @param ruleIds The rule ids to apply suggestions
     * @param filter The script to filter suggestions
     */
    applySuggestions(results: ESLint.LintResult[], ruleIds: string[], filter: SuggestionFilter): Promise<Undo>;
    /**
     * Make forcibly fixable and run `eslint --fix`.
     * @param results The lint results of the project to apply suggestions
     * @param ruleIds The rule ids to apply suggestions
     * @param fixableMaker The function to make `Linter.LintMessage` forcibly fixable.
     */
    makeFixableAndFix(results: ESLint.LintResult[], ruleIds: string[], fixableMaker: FixableMaker): Promise<Undo>;
    /**
     * Fix source codes.
     * @param fix The fix information to do.
     */
    private fix;
}
//# sourceMappingURL=core.d.ts.map