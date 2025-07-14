import { AST, ESLint, Linter, Rule, SourceCode } from 'eslint';
import type { Comment, SourceLocation } from 'estree';
export type DisableComment = {
    type: 'Block' | 'Line';
    scope: 'next-line' | 'file';
    ruleIds: string[];
    description?: string | undefined;
    range: [number, number];
    loc: SourceLocation;
};
/**
 * Parses the comment as an ESLint disable comment.
 * Returns undefined if the comment cannot be parsed as a disable comment.
 *
 * ## Reference: Structure of a disable comment
 * /* eslint-disable-next-line rule-a, rule-b, rule-c, rule-d -- I'm the rules.
 *    ^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^ ^^^^^^^^^^^^^^
 *    |                        |                              |  |
 *    header                   |                              |  |
 *                             ruleList                       |  |
 *                                            descriptionHeader  |
 *                                                               description
 */
export declare function parseDisableComment(comment: Comment): DisableComment | undefined;
/**
 * Convert text to comment text.
 */
export declare function toCommentText(args: {
    type: 'Line' | 'Block';
    text: string;
}): string;
/**
 * Convert `DisableComment` to comment text.
 */
export declare function toDisableCommentText({ type, scope, ruleIds, description, }: Omit<DisableComment, 'range' | 'loc'>): string;
export declare function isLineInTemplateLiteral(sourceCode: SourceCode, line: number): boolean;
export declare function getStartColumnOfTemplateExpression(sourceCode: SourceCode, message: Linter.LintMessage): number;
/**
 * Merge the ruleIds of the disable comments.
 * @param a The ruleIds of first disable comment
 * @param b The ruleIds of second disable comment
 * @returns The ruleIds of merged disable comment
 */
export declare function mergeRuleIds(a: string[], b: string[]): string[];
/**
 * Merge the description of the disable comments.
 * @param a The description of first disable comment
 * @param b The description of second disable comment
 * @returns The description of merged disable comment
 */
export declare function mergeDescription(a: string | undefined, b: string | undefined): string | undefined;
export declare function insertDescriptionCommentStatementBeforeLine(args: {
    fixer: Rule.RuleFixer;
    sourceCode: SourceCode;
    line: number;
    column: number;
    description: string;
}): Rule.Fix;
/**
 * Update existing disable comment.
 * @returns The eslint's fix object
 */
export declare function updateDisableComment(args: {
    fixer: Rule.RuleFixer;
    disableComment: DisableComment;
    newRules: string[];
    newDescription: string | undefined;
}): Rule.Fix;
export declare function insertDisableCommentStatementBeforeLine(args: {
    fixer: Rule.RuleFixer;
    sourceCode: SourceCode;
    line: number;
    column: number;
    scope: 'file' | 'next-line';
    ruleIds: string[];
    description: string | undefined;
}): Rule.Fix;
type InlineConfigComment = {
    description?: string | undefined;
    rulesRecord: Partial<Linter.RulesRecord>;
    range: [number, number];
};
/**
 * Convert `InlineConfigComment` to comment text.
 */
export declare function toInlineConfigCommentText({ rulesRecord, description }: Omit<InlineConfigComment, 'range'>): string;
/**
 * Create the results with only messages with the specified rule ids.
 * @param results The lint results.
 * @param ruleIds The rule ids.
 * @returns The results with only messages with the specified rule ids
 */
export declare function filterResultsByRuleId(results: ESLint.LintResult[], ruleIds: (string | null)[]): ESLint.LintResult[];
/**
 * Find shebang from the first line of the file.
 * @param sourceCodeText The source code text of the file.
 * @returns The information of shebang. If the file does not have shebang, return null.
 */
export declare function findShebang(sourceCodeText: string): {
    range: AST.Range;
} | null;
export {};
//# sourceMappingURL=eslint.d.ts.map