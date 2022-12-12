import { LintReport, Options as EslintOptions } from './types/eslint';
export declare function createEslinter(eslintOptions: EslintOptions): {
    getReport: (filepath: string) => LintReport | undefined;
};
