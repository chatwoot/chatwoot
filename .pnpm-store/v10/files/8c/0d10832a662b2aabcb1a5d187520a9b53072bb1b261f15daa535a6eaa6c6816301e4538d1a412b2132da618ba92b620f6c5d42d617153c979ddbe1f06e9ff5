/**
 * @fileoverview An object that creates fix commands for rules.
 * @author Nicholas C. Zakas
 */
import { AST, Rule } from 'eslint';
import type { Node } from 'estree';
/**
 * Creates code fixing commands for rules.
 */
/** @type {import('eslint').Rule.RuleFixer} */
declare const ruleFixer: Readonly<{
    /**
     * Creates a fix command that inserts text after the given node or token.
     * The fix is not applied until applyFixes() is called.
     * @param {ASTNode|Token} nodeOrToken The node or token to insert after.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    insertTextAfter(nodeOrToken: Node | AST.Token, text: string): Rule.Fix;
    /**
     * Creates a fix command that inserts text after the specified range in the source text.
     * The fix is not applied until applyFixes() is called.
     * @param {int[]} range The range to replace, first item is start of range, second
     *      is end of range.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    insertTextAfterRange(range: AST.Range, text: string): Rule.Fix;
    /**
     * Creates a fix command that inserts text before the given node or token.
     * The fix is not applied until applyFixes() is called.
     * @param {ASTNode|Token} nodeOrToken The node or token to insert before.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    insertTextBefore(nodeOrToken: Node | AST.Token, text: string): Rule.Fix;
    /**
     * Creates a fix command that inserts text before the specified range in the source text.
     * The fix is not applied until applyFixes() is called.
     * @param {int[]} range The range to replace, first item is start of range, second
     *      is end of range.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    insertTextBeforeRange(range: AST.Range, text: string): Rule.Fix;
    /**
     * Creates a fix command that replaces text at the node or token.
     * The fix is not applied until applyFixes() is called.
     * @param {ASTNode|Token} nodeOrToken The node or token to remove.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    replaceText(nodeOrToken: Node | AST.Token, text: string): Rule.Fix;
    /**
     * Creates a fix command that replaces text at the specified range in the source text.
     * The fix is not applied until applyFixes() is called.
     * @param {int[]} range The range to replace, first item is start of range, second
     *      is end of range.
     * @param {string} text The text to insert.
     * @returns {Object} The fix command.
     */
    replaceTextRange(range: AST.Range, text: string): Rule.Fix;
    /**
     * Creates a fix command that removes the node or token from the source.
     * The fix is not applied until applyFixes() is called.
     * @param {ASTNode|Token} nodeOrToken The node or token to remove.
     * @returns {Object} The fix command.
     */
    remove(nodeOrToken: Node | AST.Token): Rule.Fix;
    /**
     * Creates a fix command that removes the specified range of text from the source.
     * The fix is not applied until applyFixes() is called.
     * @param {int[]} range The range to remove, first item is start of range, second
     *      is end of range.
     * @returns {Object} The fix command.
     */
    removeRange(range: AST.Range): Rule.Fix;
}>;
export { ruleFixer };
//# sourceMappingURL=rule-fixer.d.ts.map