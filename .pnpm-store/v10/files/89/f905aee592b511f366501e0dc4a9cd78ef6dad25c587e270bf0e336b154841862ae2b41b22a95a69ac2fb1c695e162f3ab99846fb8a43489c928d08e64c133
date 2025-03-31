import { Linter, Rule } from 'eslint';
import type { Node } from 'estree';
import { FixContext } from './index.js';
export type FixableMaker = (message: Linter.LintMessage, node: Node | null, context: FixContext) => Rule.Fix | null | undefined;
export type FixToMakeFixableAndFixArgs = {
    fixableMaker: FixableMaker;
};
/**
 * Create fix to make fixable and fix.
 */
export declare function createFixToMakeFixableAndFix(context: FixContext, args: FixToMakeFixableAndFixArgs): Rule.Fix[];
//# sourceMappingURL=make-fixable-and-fix.d.ts.map