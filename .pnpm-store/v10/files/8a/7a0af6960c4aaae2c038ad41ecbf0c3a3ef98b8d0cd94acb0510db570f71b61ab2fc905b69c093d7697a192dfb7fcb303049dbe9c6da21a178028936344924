import { Linter, Rule, SourceCode } from 'eslint';
import { traverse } from 'estraverse';
import type { Node } from 'estree';
import { unreachable } from '../util/type-check.js';
import { FixContext } from './index.js';

export type FixableMaker = (
  message: Linter.LintMessage,
  node: Node | null,
  context: FixContext,
) => Rule.Fix | null | undefined;

export type FixToMakeFixableAndFixArgs = {
  fixableMaker: FixableMaker;
};

/**
 * Check the node is the source of the message.
 */
function isMessageSourceNode(sourceCode: SourceCode, node: Node, message: Linter.LintMessage): boolean {
  if (message.nodeType === undefined) return false;

  // In some cases there may be no `endLine` or `endColumn`.
  if (message.endLine === undefined || message.endColumn === undefined) return false;
  // If `nodeType` is exists, `range` must be exists.
  if (node.range === undefined) return unreachable();

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

function getMessageToSourceNode(sourceCode: SourceCode, messages: Linter.LintMessage[]): Map<Linter.LintMessage, Node> {
  const result = new Map<Linter.LintMessage, Node>();

  traverse(sourceCode.ast, {
    // Required to traverse extension nodes such as `JSXElement`.
    fallback: 'iteration',
    enter(node: Node) {
      for (const message of messages) {
        if (isMessageSourceNode(sourceCode, node, message)) {
          result.set(message, node);
        }
      }
    },
  });
  return result;
}

function generateFixes(context: FixContext, args: FixToMakeFixableAndFixArgs): Rule.Fix[] {
  const messageToNode = getMessageToSourceNode(context.sourceCode, context.messages);

  const fixes: Rule.Fix[] = [];
  for (const message of context.messages) {
    const node = messageToNode.get(message) ?? null;
    const fix = args.fixableMaker(message, node, context);
    if (fix) fixes.push(fix);
  }
  return fixes;
}

/**
 * Create fix to make fixable and fix.
 */
export function createFixToMakeFixableAndFix(context: FixContext, args: FixToMakeFixableAndFixArgs): Rule.Fix[] {
  return generateFixes(context, args);
}
