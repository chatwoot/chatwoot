/**
 * @fileoverview An object that caches and applies source code fixes.
 * @author Nicholas C. Zakas
 */
import { Linter } from 'eslint';
/**
 * Utility for apply fixes to source code.
 * @constructor
 */
declare function SourceCodeFixer(): void;
declare namespace SourceCodeFixer {
    var applyFixes: (sourceText: string, messages: Linter.LintMessage[], shouldFix: boolean | ((message: Linter.LintMessage) => boolean)) => {
        fixed: boolean;
        messages: Linter.LintMessage[];
        output: string;
    };
}
export { SourceCodeFixer };
//# sourceMappingURL=source-code-fixer.d.ts.map