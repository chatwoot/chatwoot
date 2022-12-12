import { AST_NODE_TYPES, AST_TOKEN_TYPES, TSESTree } from '../ts-estree';
declare const isOptionalChainPunctuator: (token: TSESTree.Token | null | undefined) => token is TSESTree.PunctuatorToken & {
    type: AST_TOKEN_TYPES.Punctuator;
} & {
    value: "?.";
};
declare const isNotOptionalChainPunctuator: (token: TSESTree.Token | null | undefined) => token is TSESTree.BooleanToken | TSESTree.BlockComment | TSESTree.LineComment | TSESTree.IdentifierToken | TSESTree.JSXIdentifierToken | TSESTree.JSXTextToken | TSESTree.KeywordToken | TSESTree.NullToken | TSESTree.NumericToken | TSESTree.PunctuatorToken | TSESTree.RegularExpressionToken | TSESTree.StringToken | TSESTree.TemplateToken;
declare const isNonNullAssertionPunctuator: (token: TSESTree.Token | null | undefined) => token is TSESTree.PunctuatorToken & {
    type: AST_TOKEN_TYPES.Punctuator;
} & {
    value: "!";
};
declare const isNotNonNullAssertionPunctuator: (token: TSESTree.Token | null | undefined) => token is TSESTree.BooleanToken | TSESTree.BlockComment | TSESTree.LineComment | TSESTree.IdentifierToken | TSESTree.JSXIdentifierToken | TSESTree.JSXTextToken | TSESTree.KeywordToken | TSESTree.NullToken | TSESTree.NumericToken | TSESTree.PunctuatorToken | TSESTree.RegularExpressionToken | TSESTree.StringToken | TSESTree.TemplateToken;
/**
 * Returns true if and only if the node represents: foo?.() or foo.bar?.()
 */
declare const isOptionalCallExpression: (node: TSESTree.Node | null | undefined) => node is TSESTree.CallExpression & {
    type: AST_NODE_TYPES.CallExpression;
} & {
    optional: true;
};
/**
 * Returns true if and only if the node represents logical OR
 */
declare const isLogicalOrOperator: (node: TSESTree.Node | null | undefined) => node is TSESTree.LogicalExpression & {
    type: AST_NODE_TYPES.LogicalExpression;
} & {
    operator: "||";
};
/**
 * Checks if a node is a type assertion:
 * ```
 * x as foo
 * <foo>x
 * ```
 */
declare const isTypeAssertion: (node: TSESTree.Node | null | undefined) => node is (TSESTree.TSAsExpression & {
    type: AST_NODE_TYPES.TSAsExpression | AST_NODE_TYPES.TSTypeAssertion;
}) | (TSESTree.TSTypeAssertion & {
    type: AST_NODE_TYPES.TSAsExpression | AST_NODE_TYPES.TSTypeAssertion;
});
declare const isVariableDeclarator: (node: TSESTree.Node | null | undefined) => node is TSESTree.VariableDeclarator & {
    type: AST_NODE_TYPES.VariableDeclarator;
};
declare const isFunction: (node: TSESTree.Node | null | undefined) => node is (TSESTree.ArrowFunctionExpression & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression;
}) | (TSESTree.FunctionDeclarationWithName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression;
}) | (TSESTree.FunctionDeclarationWithOptionalName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression;
}) | (TSESTree.FunctionExpression & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression;
});
declare const isFunctionType: (node: TSESTree.Node | null | undefined) => node is (TSESTree.TSCallSignatureDeclaration & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSConstructorType & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSConstructSignatureDeclaration & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSEmptyBodyFunctionExpression & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSFunctionType & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSMethodSignatureComputedName & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSMethodSignatureNonComputedName & {
    type: AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
});
declare const isFunctionOrFunctionType: (node: TSESTree.Node | null | undefined) => node is (TSESTree.ArrowFunctionExpression & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.FunctionDeclarationWithName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.FunctionDeclarationWithOptionalName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.FunctionExpression & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSCallSignatureDeclaration & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSConstructorType & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSConstructSignatureDeclaration & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSEmptyBodyFunctionExpression & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSFunctionType & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSMethodSignatureComputedName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
}) | (TSESTree.TSMethodSignatureNonComputedName & {
    type: AST_NODE_TYPES.ArrowFunctionExpression | AST_NODE_TYPES.FunctionDeclaration | AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructorType | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSFunctionType | AST_NODE_TYPES.TSMethodSignature;
});
declare const isTSFunctionType: (node: TSESTree.Node | null | undefined) => node is TSESTree.TSFunctionType & {
    type: AST_NODE_TYPES.TSFunctionType;
};
declare const isTSConstructorType: (node: TSESTree.Node | null | undefined) => node is TSESTree.TSConstructorType & {
    type: AST_NODE_TYPES.TSConstructorType;
};
declare const isClassOrTypeElement: (node: TSESTree.Node | null | undefined) => node is (TSESTree.FunctionExpression & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.MethodDefinitionComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.MethodDefinitionNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.PropertyDefinitionComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.PropertyDefinitionNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSAbstractMethodDefinitionComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSAbstractMethodDefinitionNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSAbstractPropertyDefinitionComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSAbstractPropertyDefinitionNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSCallSignatureDeclaration & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSConstructSignatureDeclaration & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSEmptyBodyFunctionExpression & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSIndexSignature & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSMethodSignatureComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSMethodSignatureNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSPropertySignatureComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
}) | (TSESTree.TSPropertySignatureNonComputedName & {
    type: AST_NODE_TYPES.FunctionExpression | AST_NODE_TYPES.MethodDefinition | AST_NODE_TYPES.PropertyDefinition | AST_NODE_TYPES.TSAbstractMethodDefinition | AST_NODE_TYPES.TSAbstractPropertyDefinition | AST_NODE_TYPES.TSCallSignatureDeclaration | AST_NODE_TYPES.TSConstructSignatureDeclaration | AST_NODE_TYPES.TSEmptyBodyFunctionExpression | AST_NODE_TYPES.TSIndexSignature | AST_NODE_TYPES.TSMethodSignature | AST_NODE_TYPES.TSPropertySignature;
});
/**
 * Checks if a node is a constructor method.
 */
declare const isConstructor: (node: TSESTree.Node | null | undefined) => node is (TSESTree.MethodDefinitionComputedName & {
    type: AST_NODE_TYPES.MethodDefinition;
} & {
    kind: "constructor";
}) | (TSESTree.MethodDefinitionNonComputedName & {
    type: AST_NODE_TYPES.MethodDefinition;
} & {
    kind: "constructor";
});
/**
 * Checks if a node is a setter method.
 */
declare function isSetter(node: TSESTree.Node | undefined): node is (TSESTree.MethodDefinition | TSESTree.Property) & {
    kind: 'set';
};
declare const isIdentifier: (node: TSESTree.Node | null | undefined) => node is TSESTree.Identifier & {
    type: AST_NODE_TYPES.Identifier;
};
/**
 * Checks if a node represents an `await …` expression.
 */
declare const isAwaitExpression: (node: TSESTree.Node | null | undefined) => node is TSESTree.AwaitExpression & {
    type: AST_NODE_TYPES.AwaitExpression;
};
/**
 * Checks if a possible token is the `await` keyword.
 */
declare const isAwaitKeyword: (token: TSESTree.Token | null | undefined) => token is TSESTree.IdentifierToken & {
    type: AST_TOKEN_TYPES.Identifier;
} & {
    value: "await";
};
declare const isLoop: (node: TSESTree.Node | null | undefined) => node is (TSESTree.DoWhileStatement & {
    type: AST_NODE_TYPES.DoWhileStatement | AST_NODE_TYPES.ForInStatement | AST_NODE_TYPES.ForOfStatement | AST_NODE_TYPES.ForStatement | AST_NODE_TYPES.WhileStatement;
}) | (TSESTree.ForInStatement & {
    type: AST_NODE_TYPES.DoWhileStatement | AST_NODE_TYPES.ForInStatement | AST_NODE_TYPES.ForOfStatement | AST_NODE_TYPES.ForStatement | AST_NODE_TYPES.WhileStatement;
}) | (TSESTree.ForOfStatement & {
    type: AST_NODE_TYPES.DoWhileStatement | AST_NODE_TYPES.ForInStatement | AST_NODE_TYPES.ForOfStatement | AST_NODE_TYPES.ForStatement | AST_NODE_TYPES.WhileStatement;
}) | (TSESTree.ForStatement & {
    type: AST_NODE_TYPES.DoWhileStatement | AST_NODE_TYPES.ForInStatement | AST_NODE_TYPES.ForOfStatement | AST_NODE_TYPES.ForStatement | AST_NODE_TYPES.WhileStatement;
}) | (TSESTree.WhileStatement & {
    type: AST_NODE_TYPES.DoWhileStatement | AST_NODE_TYPES.ForInStatement | AST_NODE_TYPES.ForOfStatement | AST_NODE_TYPES.ForStatement | AST_NODE_TYPES.WhileStatement;
});
export { isAwaitExpression, isAwaitKeyword, isConstructor, isClassOrTypeElement, isFunction, isFunctionOrFunctionType, isFunctionType, isIdentifier, isLoop, isLogicalOrOperator, isNonNullAssertionPunctuator, isNotNonNullAssertionPunctuator, isNotOptionalChainPunctuator, isOptionalChainPunctuator, isOptionalCallExpression, isSetter, isTSConstructorType, isTSFunctionType, isTypeAssertion, isVariableDeclarator, };
//# sourceMappingURL=predicates.d.ts.map