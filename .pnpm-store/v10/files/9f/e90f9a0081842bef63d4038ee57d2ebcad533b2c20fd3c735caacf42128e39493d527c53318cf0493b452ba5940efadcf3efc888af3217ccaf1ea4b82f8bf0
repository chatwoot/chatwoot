import { ESLint, Linter, Rule } from 'eslint';

/** @deprecated */
export const LegacyESLint: typeof ESLint;

/** @deprecated */
// eslint-disable-next-line @typescript-eslint/no-namespace
export namespace FlatESLint {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface Options {
    // File enumeration
    cwd?: string | undefined;
    errorOnUnmatchedPattern?: boolean | undefined;
    globInputPaths?: boolean | undefined;
    ignore?: boolean | undefined;

    // Linting
    allowInlineConfig?: boolean | undefined;
    baseConfig?: Linter.FlatConfig | Linter.FlatConfig[] | undefined;
    overrideConfig?: Linter.FlatConfig | Linter.FlatConfig[] | undefined;
    overrideConfigFile?: boolean | string | undefined;
    reportUnusedDisableDirectives?: Linter.StringSeverity | undefined;

    // Autofix
    fix?: boolean | ((message: Linter.LintMessage) => boolean) | undefined;
    fixTypes?: Rule.RuleMetaData['type'][] | undefined;

    // Cache-related
    cache?: boolean | undefined;
    cacheLocation?: string | undefined;
    cacheStrategy?: 'content' | 'metadata' | undefined;
  }
}
/** @deprecated */
export declare class FlatESLint {
  constructor(options?: FlatESLint.Options);

  static get version(): string;

  static outputFixes(results: ESLint.LintResult[]): Promise<void>;

  static getErrorResults(results: ESLint.LintResult[]): ESLint.LintResult[];

  getRulesMetaForResults(results: ESLint.LintResult[]): Record<string, Rule.RuleMetaData>;

  lintFiles(patterns: string | string[]): Promise<ESLint.LintResult[]>;

  lintText(
    code: string,
    options?: { filePath?: string | undefined; warnIgnored?: boolean | undefined },
  ): Promise<ESLint.LintResult[]>;

  loadFormatter(name?: string): Promise<ESLint.Formatter>;

  calculateConfigForFile(filePath: string): Promise<Linter.FlatConfig | undefined>;

  findConfigFile(): Promise<string | undefined>;

  isPathIgnored(filePath: string): Promise<boolean>;
}
/** @deprecated */
export function shouldUseFlatConfig(): Promise<boolean>;
