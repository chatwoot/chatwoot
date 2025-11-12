import { writeFile } from 'node:fs/promises';
import { ESLint, Rule } from 'eslint';
import { DescriptionPosition } from './cli/prompt.js';
import { Config, NormalizedConfig, normalizeConfig } from './config.js';
import { LegacyESLint, FlatESLint } from './eslint/use-at-your-own-risk.js';
import {
  createFixToApplyAutoFixes,
  createFixToApplySuggestions,
  createFixToConvertErrorToWarningPerFile,
  createFixToDisablePerFile,
  createFixToDisablePerLine,
  createFixToMakeFixableAndFix,
  FixableMaker,
  SuggestionFilter,
  FixContext,
  verifyAndFix,
} from './fix/index.js';
import { format } from './formatter/index.js';
import { plugin } from './plugin.js';
import { filterResultsByRuleId } from './util/eslint.js';

/**
 * Generate results to undo.
 * @param resultsOfLint The results of lint.
 * @returns The results to undo.
 */
function generateResultsToUndo(resultsOfLint: ESLint.LintResult[]): ESLint.LintResult[] {
  return resultsOfLint.map((resultOfLint) => {
    // NOTE: THIS IS HACK.
    return { ...resultOfLint, output: resultOfLint.source };
  });
}

export type Undo = () => Promise<void>;

/**
 * The core of eslint-interactive.
 * It uses ESLint's Node.js API to output a summary of problems, fix problems, apply suggestions, etc.
 */
export class Core {
  readonly config: NormalizedConfig;
  readonly eslint: ESLint;

  constructor(config: Config) {
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
    } else {
      const { type, ...rest } = eslintOptions;
      const overrideConfigs =
        Array.isArray(rest.overrideConfig) ? rest.overrideConfig
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
  async lint(): Promise<ESLint.LintResult[]> {
    let results = await this.eslint.lintFiles(this.config.patterns);
    if (this.config.quiet) results = LegacyESLint.getErrorResults(results);
    return results;
  }

  /**
   * Returns summary of lint results.
   * @param results The lint results of the project to print summary
   */
  formatResultSummary(results: ESLint.LintResult[]): string {
    const rulesMeta = this.eslint.getRulesMetaForResults(results);
    return format(results, { rulesMeta, cwd: this.config.cwd });
  }

  /**
   * Returns details of lint results.
   * @param results The lint results of the project to print summary
   * @param ruleIds The rule ids to print details
   */
  async formatResultDetails(results: ESLint.LintResult[], ruleIds: (string | null)[]): Promise<string> {
    const formatterName = this.config.formatterName;
    const formatter = await this.eslint.loadFormatter(formatterName);
    return formatter.format(filterResultsByRuleId(results, ruleIds));
  }

  /**
   * Run `eslint --fix`.
   * @param ruleIds The rule ids to fix
   */
  async applyAutoFixes(results: ESLint.LintResult[], ruleIds: string[]): Promise<Undo> {
    return this.fix(results, ruleIds, (context) => createFixToApplyAutoFixes(context, {}));
  }

  /**
   * Add disable comments per line.
   * @param results The lint results of the project to add disable comments
   * @param ruleIds The rule ids to add disable comments
   * @param description The description of the disable comments
   * @param descriptionPosition The position of the description
   */
  async disablePerLine(
    results: ESLint.LintResult[],
    ruleIds: string[],
    description?: string,
    descriptionPosition?: DescriptionPosition,
  ): Promise<Undo> {
    return this.fix(results, ruleIds, (context) =>
      createFixToDisablePerLine(context, { description, descriptionPosition }),
    );
  }

  /**
   * Add disable comments per file.
   * @param results The lint results of the project to add disable comments
   * @param ruleIds The rule ids to add disable comments
   * @param description The description of the disable comments
   * @param descriptionPosition The position of the description
   */
  async disablePerFile(
    results: ESLint.LintResult[],
    ruleIds: string[],
    description?: string,
    descriptionPosition?: DescriptionPosition,
  ): Promise<Undo> {
    return this.fix(results, ruleIds, (context) =>
      createFixToDisablePerFile(context, { description, descriptionPosition }),
    );
  }

  /**
   * Convert error to warning per file.
   * @param results The lint results of the project to convert
   * @param ruleIds The rule ids to convert
   * @param description The comment explaining the reason for converting
   */
  async convertErrorToWarningPerFile(
    results: ESLint.LintResult[],
    ruleIds: string[],
    description?: string,
  ): Promise<Undo> {
    return this.fix(results, ruleIds, (context) => createFixToConvertErrorToWarningPerFile(context, { description }));
  }

  /**
   * Apply suggestions.
   * @param results The lint results of the project to apply suggestions
   * @param ruleIds The rule ids to apply suggestions
   * @param filter The script to filter suggestions
   */
  async applySuggestions(results: ESLint.LintResult[], ruleIds: string[], filter: SuggestionFilter): Promise<Undo> {
    return this.fix(results, ruleIds, (context) => createFixToApplySuggestions(context, { filter }));
  }

  /**
   * Make forcibly fixable and run `eslint --fix`.
   * @param results The lint results of the project to apply suggestions
   * @param ruleIds The rule ids to apply suggestions
   * @param fixableMaker The function to make `Linter.LintMessage` forcibly fixable.
   */
  async makeFixableAndFix(results: ESLint.LintResult[], ruleIds: string[], fixableMaker: FixableMaker): Promise<Undo> {
    return this.fix(results, ruleIds, (context) => createFixToMakeFixableAndFix(context, { fixableMaker }));
  }

  /**
   * Fix source codes.
   * @param fix The fix information to do.
   */
  private async fix(
    resultsOfLint: ESLint.LintResult[],
    ruleIds: string[],
    fixCreator: (context: FixContext) => Rule.Fix[],
  ): Promise<Undo> {
    // NOTE: Extract only necessary results and files for performance
    const filteredResultsOfLint = filterResultsByRuleId(resultsOfLint, ruleIds);

    // eslint-disable-next-line prefer-const
    for (let { filePath, source } of filteredResultsOfLint) {
      if (!source) throw new Error('Source code is required to apply fixes.');

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
