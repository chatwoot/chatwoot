import type { ParsedNode } from '../nodes/Node.js';
import type { BlockMap, BlockSequence, FlowCollection, SourceToken } from '../parse/cst.js';
import type { ComposeContext, ComposeNode } from './compose-node.js';
import type { ComposeErrorHandler } from './composer.js';
interface Props {
    anchor: SourceToken | null;
    tag: SourceToken | null;
    newlineAfterProp: SourceToken | null;
}
export declare function composeCollection(CN: ComposeNode, ctx: ComposeContext, token: BlockMap | BlockSequence | FlowCollection, props: Props, onError: ComposeErrorHandler): ParsedNode;
export {};
