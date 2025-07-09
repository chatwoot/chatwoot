/**
 * @fileoverview Main Linter Class
 * @author Gyandeep Singh
 * @author aladdin-add
 */
import { ESLint, Rule } from 'eslint';
import { FixContext } from '../fix/index.js';
type FixedResult = {
    fixed: boolean;
    output: string;
};
/**
 * Performs multiple autofix passes over the text until as many fixes as possible have been applied.
 * @param linter
 */
export declare function verifyAndFix(eslint: ESLint, text: string, filePath: string, ruleIds: string[], fixCreator: (context: FixContext) => Rule.Fix[]): Promise<FixedResult>;
export {};
//# sourceMappingURL=linter.d.ts.map