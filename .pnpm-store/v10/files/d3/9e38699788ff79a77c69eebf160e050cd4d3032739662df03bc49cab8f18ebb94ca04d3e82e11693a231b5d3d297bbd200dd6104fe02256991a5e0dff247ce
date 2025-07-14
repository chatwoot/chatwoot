let lastSourceCode = null;
export function getLastSourceCode() {
    return lastSourceCode;
}
export const plugin = {
    rules: {
        /**
         * This is a rule for getting a `SourceCode` instance.
         * `ESLint` class does not provide a method for getting a `SourceCode` instance. As an alternative, we have prepared this custom rule.
         */
        'source-code-snatcher': {
            create(context) {
                lastSourceCode = context.sourceCode;
                return {};
            },
        },
        /** This is a rule for testing purposes. */
        'prefer-addition-shorthand': {
            meta: {
                type: 'suggestion',
                // @ts-ignore
                hasSuggestions: true,
            },
            create(context) {
                return {
                    // eslint-disable-next-line @typescript-eslint/naming-convention
                    AssignmentExpression: (node) => {
                        if (node.left.type !== 'Identifier')
                            return;
                        const leftIdentifier = node.left;
                        if (node.right.type !== 'BinaryExpression')
                            return;
                        const rightBinaryExpression = node.right;
                        if (rightBinaryExpression.operator !== '+')
                            return;
                        if (rightBinaryExpression.left.type !== 'Identifier')
                            return;
                        const rightIdentifier = rightBinaryExpression.left;
                        if (leftIdentifier.name !== rightIdentifier.name)
                            return;
                        if (rightBinaryExpression.right.type !== 'Literal' || rightBinaryExpression.right.value !== 1)
                            return;
                        context.report({
                            node,
                            message: 'The addition method is redundant.',
                            suggest: [
                                {
                                    desc: 'Use `val += 1` instead.',
                                    fix(fixer) {
                                        return fixer.replaceText(node, `${leftIdentifier.name} += 1`);
                                    },
                                },
                                {
                                    desc: 'Use `val++` instead.',
                                    fix(fixer) {
                                        return fixer.replaceText(node, `${leftIdentifier.name}++`);
                                    },
                                },
                                {
                                    desc: 'Use `++val` instead.',
                                    fix(fixer) {
                                        return fixer.replaceText(node, `++${leftIdentifier.name}`);
                                    },
                                },
                            ],
                        });
                    },
                };
            },
        },
    },
};
//# sourceMappingURL=plugin.js.map