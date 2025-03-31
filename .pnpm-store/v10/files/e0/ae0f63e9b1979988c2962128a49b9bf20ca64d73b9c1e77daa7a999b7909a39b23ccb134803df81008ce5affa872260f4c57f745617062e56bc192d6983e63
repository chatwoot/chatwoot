import { ESLint } from 'eslint';
import { Config } from './config.js';
import { Core } from './core.js';
/**
 * This is a wrapper for using the Core API from comlink.
 *
 * The arguments of the methods wrapped in comlink must be serializable.
 * The methods in this class are serializable versions of the Core API methods.
 */
export declare class SerializableCore {
    readonly core: Core;
    constructor(config: Config);
    lint(...args: Parameters<Core['lint']>): ReturnType<Core['lint']>;
    formatResultSummary(...args: Parameters<Core['formatResultSummary']>): ReturnType<Core['formatResultSummary']>;
    formatResultDetails(...args: Parameters<Core['formatResultDetails']>): ReturnType<Core['formatResultDetails']>;
    applyAutoFixes(...args: Parameters<Core['applyAutoFixes']>): ReturnType<Core['applyAutoFixes']>;
    disablePerLine(...args: Parameters<Core['disablePerLine']>): ReturnType<Core['disablePerLine']>;
    disablePerFile(...args: Parameters<Core['disablePerFile']>): ReturnType<Core['disablePerFile']>;
    convertErrorToWarningPerFile(...args: Parameters<Core['convertErrorToWarningPerFile']>): ReturnType<Core['convertErrorToWarningPerFile']>;
    applySuggestions(results: ESLint.LintResult[], ruleIds: string[], filterScript: string): ReturnType<Core['applySuggestions']>;
    makeFixableAndFix(results: ESLint.LintResult[], ruleIds: string[], fixableMakerScript: string): ReturnType<Core['makeFixableAndFix']>;
}
//# sourceMappingURL=core-worker.d.ts.map