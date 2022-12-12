import { AST_NODE_TYPES, AST_TOKEN_TYPES, TSESTree } from '../ts-estree';
export declare const isNodeOfType: <NodeType extends AST_NODE_TYPES>(nodeType: NodeType) => (node: TSESTree.Node | null | undefined) => node is TSESTree.Node & {
    type: NodeType;
};
export declare const isNodeOfTypes: <NodeTypes extends readonly AST_NODE_TYPES[]>(nodeTypes: NodeTypes) => (node: TSESTree.Node | null | undefined) => node is TSESTree.Node & {
    type: NodeTypes[number];
};
export declare const isNodeOfTypeWithConditions: <NodeType extends AST_NODE_TYPES, Conditions extends Partial<TSESTree.Node & {
    type: NodeType;
}>>(nodeType: NodeType, conditions: Conditions) => (node: TSESTree.Node | null | undefined) => node is TSESTree.Node & {
    type: NodeType;
} & Conditions;
export declare const isTokenOfTypeWithConditions: <TokenType extends AST_TOKEN_TYPES, Conditions extends Partial<TSESTree.Token & {
    type: TokenType;
}>>(tokenType: TokenType, conditions: Conditions) => (token: TSESTree.Token | null | undefined) => token is TSESTree.Token & {
    type: TokenType;
} & Conditions;
export declare const isNotTokenOfTypeWithConditions: <TokenType extends AST_TOKEN_TYPES, Conditions extends Partial<TSESTree.Token & {
    type: TokenType;
}>>(tokenType: TokenType, conditions: Conditions) => (token: TSESTree.Token | null | undefined) => token is Exclude<TSESTree.BooleanToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.BlockComment, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.LineComment, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.IdentifierToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.JSXIdentifierToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.JSXTextToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.KeywordToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.NullToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.NumericToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.PunctuatorToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.RegularExpressionToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.StringToken, TSESTree.Token & {
    type: TokenType;
} & Conditions> | Exclude<TSESTree.TemplateToken, TSESTree.Token & {
    type: TokenType;
} & Conditions>;
//# sourceMappingURL=helpers.d.ts.map