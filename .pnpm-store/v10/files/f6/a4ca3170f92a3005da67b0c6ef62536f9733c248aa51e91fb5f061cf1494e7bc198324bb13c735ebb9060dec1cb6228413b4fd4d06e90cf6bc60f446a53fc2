import { writeFile } from 'node:fs/promises';
import { normalizeConfig } from './config.js';
import { LegacyESLint, FlatESLint } from './eslint/use-at-your-own-risk.js';
import { createFixToApplyAutoFixes, createFixToApplySuggestions, createFixToConvertErrorToWarningPerFile, createFixToDisablePerFile, createFixToDisablePerLine, createFixToMakeFixableAndFix, verifyAndFix, } from './fix/index.js';
import { format } from './formatter/index.js';
import { plugin } from './plugin.js';
import { filterResultsByRuleId } from './util/eslint.js';
/**
 * Generate results to undo.
 * @param resultsOfLint The results of lint.
 * @returns The results to undo.
 */
function generateResultsToUndo(resultsOfLint) {
    return resultsOfLint.map((resultOfLint) => {
        // NOTE: THIS IS HACK.
        return { ...resultOfLint, output: resultOfLint.source };
    });
}
/**
 * The core of eslint-interactive.
 * It uses ESLint's Node.js API to output a summary of problems, fix problems, apply suggestions, etc.
 */
export class Core {
    config;
    eslint;
    constructor(config) {
        this.config = normalizeConfig(config);
        const eslintOptions = this.config.eslintOptions;
        if (eslintOptions.type === 'eslintrc') {
            const { type, ...rest } = eslintOptions;
            this.eslint = new LegacyESLint({
                ...rest,
                plugins: {
                    ...rest.plugins,
                    'eslint-interactive': plugin,
                },
                overrideConfig: {
                    ...rest.overrideConfig,
                    plugins: [...(rest.overrideConfig?.plugins ?? []), 'eslint-interactive'],
                    rules: {
                        ...rest.overrideConfig?.rules,
                        'eslint-interactive/source-code-snatcher': 'error',
                    },
                },
            });
        }
        else {
            const { type, ...rest } = eslintOptions;
            const overrideConfigs = Array.isArray(rest.overrideConfig) ? rest.overrideConfig
                : rest.overrideConfig ? [rest.overrideConfig]
                    : [];
            this.eslint = new FlatESLint({
                ...rest,
                overrideConfig: [
                    ...overrideConfigs,
                    {
                        ...rest.overrideConfig,
                        plugins: { 'eslint-interactive': plugin },
                        rules: {
                            'eslint-interactive/source-code-snatcher': 'error',
                        },
                    },
                ],
            });
        }
    }
    /**
     * Lint project.
     * @returns The results of linting
     */
    async lint() {
        let results = await this.eslint.lintFiles(this.config.patterns);
        if (this.config.quiet)
            results = LegacyESLint.getErrorResults(results);
        return results;
    }
    /**
     * Returns summary of lint results.
     * @param results The lint results of the project to print summary
     */
    formatResultSummary(results) {
        const rulesMeta = this.eslint.getRulesMetaForResults(results);
        return format(results, { rulesMeta, cwd: this.config.cwd });
    }
    /**
     * Returns details of lint results.
     * @param results The lint results of the project to print summary
     * @param ruleIds The rule ids to print details
     */
    async formatResultDetails(results, ruleIds) {
        const formatterName = this.config.formatterName;
        const formatter = await this.eslint.loadFormatter(formatterName);
        return formatter.format(filterResultsByRuleId(results, ruleIds));
    }
    /**
     * Run `eslint --fix`.
     * @param ruleIds The rule ids to fix
     */
    async applyAutoFixes(results, ruleIds) {
        return this.fix(results, ruleIds, (context) => createFixToApplyAutoFixes(context, {}));
    }
    /**
     * Add disable comments per line.
     * @param results The lint results of the project to add disable comments
     * @param ruleIds The rule ids to add disable comments
     * @param description The description of the disable comments
     * @param descriptionPosition The position of the description
     */
    async disablePerLine(results, ruleIds, description, descriptionPosition) {
        return this.fix(results, ruleIds, (context) => createFixToDisablePerLine(context, { description, descriptionPosition }));
    }
    /**
     * Add disable comments per file.
     * @param results The lint results of the project to add disable comments
     * @param ruleIds The rule ids to add disable comments
     * @param description The description of the disable comments
     * @param descriptionPosition The position of the description
     */
    async disablePerFile(results, ruleIds, description, descriptionPosition) {
        return this.fix(results, ruleIds, (context) => createFixToDisablePerFile(context, { description, descriptionPosition }));
    }
    /**
     * Convert error to warning per file.
     * @param results The lint results of the project to convert
     * @param ruleIds The rule ids to convert
     * @param description The comment explaining the reason for converting
     */
    async convertErrorToWarningPerFile(results, ruleIds, description) {
        return this.fix(results, ruleIds, (context) => createFixToConvertErrorToWarningPerFile(context, { description }));
    }
    /**
     * Apply suggestions.
     * @param results The lint results of the project to apply suggestions
     * @param ruleIds The rule ids to apply suggestions
     * @param filter The script to filter suggestions
     */
    async applySuggestions(results, ruleIds, filter) {
        return this.fix(results, ruleIds, (context) => createFixToApplySuggestions(context, { filter }));
    }
    /**
     * Make forcibly fixable and run `eslint --fix`.
     * @param results The lint results of the project to apply suggestions
     * @param ruleIds The rule ids to apply suggestions
     * @param fixableMaker The function to make `Linter.LintMessage` forcibly fixable.
     */
    async makeFixableAndFix(results, ruleIds, fixableMaker) {
        return this.fix(results, ruleIds, (context) => createFixToMakeFixableAndFix(context, { fixableMaker }));
    }
    /**
     * Fix source codes.
     * @param fix The fix information to do.
     */
    async fix(resultsOfLint, ruleIds, fixCreator) {
        // NOTE: Extract only necessary results and files for performance
        const filteredResultsOfLint = filterResultsByRuleId(resultsOfLint, ruleIds);
        // eslint-disable-next-line prefer-const
        for (let { filePath, source } of filteredResultsOfLint) {
            if (!source)
                throw new Error('Source code is required to apply fixes.');
            // eslint-disable-next-line no-await-in-loop
            const fixedResult = await verifyAndFix(this.eslint, source, filePath, ruleIds, fixCreator);
            // Write the fixed source code to the file
            if (fixedResult.fixed) {
                // eslint-disable-next-line no-await-in-loop, @typescript-eslint/no-non-null-assertion
                await writeFile(filePath, fixedResult.output);
            }
        }
        return async () => {
            const resultsToUndo = generateResultsToUndo(filteredResultsOfLint);
            await LegacyESLint.outputFixes(resultsToUndo);
        };
    }
}
//# sourceMappingURL=core.js.map