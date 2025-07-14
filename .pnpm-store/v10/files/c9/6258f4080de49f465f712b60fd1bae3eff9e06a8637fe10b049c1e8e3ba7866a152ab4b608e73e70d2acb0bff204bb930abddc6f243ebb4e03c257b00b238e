import { traverse } from 'estraverse';
import { unreachable } from '../util/type-check.js';
/**
 * Check the node is the source of the message.
 */
function isMessageSourceNode(sourceCode, node, message) {
    if (message.nodeType === undefined)
        return false;
    // In some cases there may be no `endLine` or `endColumn`.
    if (message.endLine === undefined || message.endColumn === undefined)
        return false;
    // If `nodeType` is exists, `range` must be exists.
    if (node.range === undefined)
        return unreachable();
    const index = sourceCode.getIndexFromLoc({
        line: message.line,
        // NOTE: `column` of `ESLint.LintMessage` is 1-based, but `column` of `ESTree.Position` is 0-based.
        column: message.column - 1,
    });
    const endIndex = sourceCode.getIndexFromLoc({
        line: message.endLine,
        // NOTE: `column` of `ESLint.LintMessage` is 1-based, but `column` of `ESTree.Position` is 0-based.
        column: message.endColumn - 1,
    });
    const nodeType = message.nodeType;
    return node.range[0] === index && node.range[1] === endIndex && node.type === nodeType;
}
function getMessageToSourceNode(sourceCode, messages) {
    const result = new Map();
    traverse(sourceCode.ast, {
        // Required to traverse extension nodes such as `JSXElement`.
        fallback: 'iteration',
        enter(node) {
            for (const message of messages) {
                if (isMessageSourceNode(sourceCode, node, message)) {
                    result.set(message, node);
                }
            }
        },
    });
    return result;
}
function generateFixes(context, args) {
    const messageToNode = getMessageToSourceNode(context.sourceCode, context.messages);
    const fixes = [];
    for (const message of context.messages) {
        const node = messageToNode.get(message) ?? null;
        const fix = args.fixableMaker(message, node, context);
        if (fix)
            fixes.push(fix);
    }
    return fixes;
}
/**
 * Create fix to make fixable and fix.
 */
export function createFixToMakeFixableAndFix(context, args) {
    return generateFixes(context, args);
}
//# sourceMappingURL=make-fixable-and-fix.js.map