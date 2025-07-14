"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isStaticValueIdentifier = exports.validateNode = void 0;
const errors_1 = require("./errors");
const token_store_1 = require("./token-store");
const utils_1 = require("./utils");
const lineBreakPattern = /\r\n|[\n\r\u2028\u2029]/u;
const octalNumericLiteralPattern = /^0o/iu;
const legacyOctalNumericLiteralPattern = /^0\d/u;
const binaryNumericLiteralPattern = /^0b/iu;
const unicodeCodepointEscapePattern = /\\u\{[\dA-Fa-f]+\}/uy;
function hasUnicodeCodepointEscapes(code) {
    let escaped = false;
    for (let index = 0; index < code.length - 4; index++) {
        if (escaped) {
            escaped = false;
            continue;
        }
        const char = code[index];
        if (char === "\\") {
            unicodeCodepointEscapePattern.lastIndex = index;
            if (unicodeCodepointEscapePattern.test(code)) {
                return true;
            }
            escaped = true;
        }
    }
    return false;
}
function validateNode(node, tokens, ctx) {
    if (node.type === "ObjectExpression") {
        validateObjectExpressionNode(node, tokens, ctx);
        return;
    }
    if (node.type === "Property") {
        validatePropertyNode(node, tokens, ctx);
        return;
    }
    if (node.type === "ArrayExpression") {
        validateArrayExpressionNode(node, tokens, ctx);
        return;
    }
    if (node.type === "Literal") {
        validateLiteralNode(node, tokens, ctx);
        return;
    }
    if (node.type === "UnaryExpression") {
        validateUnaryExpressionNode(node, tokens, ctx);
        return;
    }
    if (node.type === "Identifier") {
        validateIdentifierNode(node, tokens, ctx);
        return;
    }
    if (node.type === "TemplateLiteral") {
        validateTemplateLiteralNode(node, tokens, ctx);
        return;
    }
    if (node.type === "TemplateElement") {
        validateTemplateElementNode(node, tokens);
        return;
    }
    if (node.type === "BinaryExpression") {
        validateBinaryExpressionNode(node, tokens, ctx);
        return;
    }
    throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
}
exports.validateNode = validateNode;
function validateObjectExpressionNode(node, tokens, ctx) {
    if (node.type !== "ObjectExpression") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    for (const prop of node.properties) {
        setParent(prop, node);
    }
    if (!ctx.trailingCommas) {
        const token = tokens.getTokenBefore(tokens.getLastToken(node));
        if (token && (0, token_store_1.isComma)(token)) {
            throw (0, errors_1.throwUnexpectedTokenError)(",", token);
        }
    }
}
function validatePropertyNode(node, tokens, ctx) {
    if (node.type !== "Property") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    setParent(node.key, node);
    setParent(node.value, node);
    if (node.computed) {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (node.method) {
        throw (0, errors_1.throwUnexpectedNodeError)(node.value, tokens);
    }
    if (node.shorthand) {
        throw (0, errors_1.throwExpectedTokenError)(":", node);
    }
    if (node.kind !== "init") {
        throw (0, errors_1.throwExpectedTokenError)(":", tokens.getFirstToken(node));
    }
    if (node.key.type === "Literal") {
        const keyValueType = typeof node.key.value;
        if (keyValueType === "number") {
            if (!ctx.numberProperties) {
                throw (0, errors_1.throwUnexpectedNodeError)(node.key, tokens);
            }
        }
        else if (keyValueType !== "string") {
            throw (0, errors_1.throwUnexpectedNodeError)(node.key, tokens);
        }
    }
    else if (node.key.type === "Identifier") {
        if (!ctx.unquoteProperties) {
            throw (0, errors_1.throwUnexpectedNodeError)(node.key, tokens);
        }
    }
    else {
        throw (0, errors_1.throwUnexpectedNodeError)(node.key, tokens);
    }
    if (node.value.type === "Identifier") {
        if (!isStaticValueIdentifier(node.value, ctx)) {
            throw (0, errors_1.throwUnexpectedNodeError)(node.value, tokens);
        }
    }
}
function validateArrayExpressionNode(node, tokens, ctx) {
    if (node.type !== "ArrayExpression") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (!ctx.trailingCommas) {
        const token = tokens.getTokenBefore(tokens.getLastToken(node));
        if (token && (0, token_store_1.isComma)(token)) {
            throw (0, errors_1.throwUnexpectedTokenError)(",", token);
        }
    }
    node.elements.forEach((child, index) => {
        if (!child) {
            if (ctx.sparseArrays) {
                return;
            }
            const beforeIndex = index - 1;
            const before = beforeIndex >= 0
                ? tokens.getLastToken(node.elements[beforeIndex])
                : tokens.getFirstToken(node);
            throw (0, errors_1.throwUnexpectedTokenError)(",", tokens.getTokenAfter(before, token_store_1.isComma));
        }
        if (child.type === "Identifier") {
            if (!isStaticValueIdentifier(child, ctx)) {
                throw (0, errors_1.throwUnexpectedNodeError)(child, tokens);
            }
        }
        setParent(child, node);
    });
}
function validateLiteralNode(node, tokens, ctx) {
    if (node.type !== "Literal") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if ((0, utils_1.isRegExpLiteral)(node)) {
        if (!ctx.regExpLiterals) {
            throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
        }
    }
    else if (node.bigint) {
        if (!ctx.bigintLiterals) {
            throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
        }
    }
    else {
        validateLiteral(node, ctx);
    }
}
function validateLiteral(node, ctx) {
    const value = node.value;
    if ((!ctx.invalidJsonNumbers ||
        !ctx.leadingOrTrailingDecimalPoints ||
        !ctx.numericSeparators) &&
        typeof value === "number") {
        const text = node.raw;
        if (!ctx.leadingOrTrailingDecimalPoints) {
            if (text.startsWith(".")) {
                throw (0, errors_1.throwUnexpectedTokenError)(".", node);
            }
            if (text.endsWith(".")) {
                throw (0, errors_1.throwUnexpectedTokenError)(".", {
                    range: [node.range[1] - 1, node.range[1]],
                    loc: {
                        start: {
                            line: node.loc.end.line,
                            column: node.loc.end.column - 1,
                        },
                        end: node.loc.end,
                    },
                });
            }
        }
        if (!ctx.numericSeparators) {
            if (text.includes("_")) {
                const index = text.indexOf("_");
                throw (0, errors_1.throwUnexpectedTokenError)("_", {
                    range: [node.range[0] + index, node.range[0] + index + 1],
                    loc: {
                        start: {
                            line: node.loc.start.line,
                            column: node.loc.start.column + index,
                        },
                        end: {
                            line: node.loc.start.line,
                            column: node.loc.start.column + index + 1,
                        },
                    },
                });
            }
        }
        if (!ctx.octalNumericLiterals) {
            if (octalNumericLiteralPattern.test(text)) {
                throw (0, errors_1.throwUnexpectedError)("octal numeric literal", node);
            }
        }
        if (!ctx.legacyOctalNumericLiterals) {
            if (legacyOctalNumericLiteralPattern.test(text)) {
                throw (0, errors_1.throwUnexpectedError)("legacy octal numeric literal", node);
            }
        }
        if (!ctx.binaryNumericLiterals) {
            if (binaryNumericLiteralPattern.test(text)) {
                throw (0, errors_1.throwUnexpectedError)("binary numeric literal", node);
            }
        }
        if (!ctx.invalidJsonNumbers) {
            try {
                JSON.parse(text);
            }
            catch (_a) {
                throw (0, errors_1.throwInvalidNumberError)(text, node);
            }
        }
    }
    if ((!ctx.multilineStrings ||
        !ctx.singleQuotes ||
        !ctx.unicodeCodepointEscapes) &&
        typeof value === "string") {
        if (!ctx.singleQuotes) {
            if (node.raw.startsWith("'")) {
                throw (0, errors_1.throwUnexpectedError)("single quoted", node);
            }
        }
        if (!ctx.multilineStrings) {
            if (lineBreakPattern.test(node.raw)) {
                throw (0, errors_1.throwUnexpectedError)("multiline string", node);
            }
        }
        if (!ctx.unicodeCodepointEscapes) {
            if (hasUnicodeCodepointEscapes(node.raw)) {
                throw (0, errors_1.throwUnexpectedError)("unicode codepoint escape", node);
            }
        }
    }
    return undefined;
}
function validateUnaryExpressionNode(node, tokens, ctx) {
    if (node.type !== "UnaryExpression") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    const operator = node.operator;
    if (operator === "+") {
        if (!ctx.plusSigns) {
            throw (0, errors_1.throwUnexpectedTokenError)("+", node);
        }
    }
    else if (operator !== "-") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    const argument = node.argument;
    if (argument.type === "Literal") {
        if (typeof argument.value !== "number") {
            throw (0, errors_1.throwUnexpectedNodeError)(argument, tokens);
        }
    }
    else if (argument.type === "Identifier") {
        if (!isNumberIdentifier(argument, ctx)) {
            throw (0, errors_1.throwUnexpectedNodeError)(argument, tokens);
        }
    }
    else {
        throw (0, errors_1.throwUnexpectedNodeError)(argument, tokens);
    }
    if (!ctx.spacedSigns) {
        if (node.range[0] + 1 < argument.range[0]) {
            throw (0, errors_1.throwUnexpectedSpaceError)(tokens.getFirstToken(node));
        }
    }
    setParent(argument, node);
}
function validateIdentifierNode(node, tokens, ctx) {
    if (node.type !== "Identifier") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (!ctx.escapeSequenceInIdentifier) {
        if (node.name.length < node.range[1] - node.range[0]) {
            throw (0, errors_1.throwUnexpectedError)("escape sequence", node);
        }
    }
}
function validateTemplateLiteralNode(node, tokens, ctx) {
    if (node.type !== "TemplateLiteral") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (!ctx.templateLiterals) {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (node.expressions.length) {
        const token = tokens.getFirstToken(node.quasis[0]);
        const loc = {
            loc: {
                start: {
                    line: token.loc.end.line,
                    column: token.loc.end.column - 2,
                },
                end: token.loc.end,
            },
            range: [token.range[1] - 2, token.range[1]],
        };
        throw (0, errors_1.throwUnexpectedTokenError)("$", loc);
    }
    if (!ctx.unicodeCodepointEscapes) {
        if (hasUnicodeCodepointEscapes(node.quasis[0].value.raw)) {
            throw (0, errors_1.throwUnexpectedError)("unicode codepoint escape", node);
        }
    }
    for (const q of node.quasis) {
        setParent(q, node);
    }
}
function validateTemplateElementNode(node, tokens) {
    if (node.type !== "TemplateElement") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    const { cooked } = node.value;
    if (cooked == null) {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    const startOffset = -1;
    const endOffset = node.tail ? 1 : 2;
    node.start += startOffset;
    node.end += endOffset;
    node.range[0] += startOffset;
    node.range[1] += endOffset;
    node.loc.start.column += startOffset;
    node.loc.end.column += endOffset;
}
function validateBinaryExpressionNode(node, tokens, ctx) {
    if (node.type !== "BinaryExpression") {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    if (!ctx.staticExpressions) {
        throw (0, errors_1.throwUnexpectedNodeError)(node, tokens);
    }
    const { operator, left, right } = node;
    if (operator !== "+" &&
        operator !== "-" &&
        operator !== "*" &&
        operator !== "/" &&
        operator !== "%" &&
        operator !== "**") {
        throw throwOperatorError();
    }
    validateExpr(left, throwOperatorError);
    validateExpr(right, () => (0, errors_1.throwUnexpectedNodeError)(right, tokens));
    function validateExpr(expr, throwError) {
        if (expr.type === "Literal") {
            if (typeof expr.value !== "number") {
                throw throwError();
            }
        }
        else if (expr.type !== "BinaryExpression" &&
            expr.type !== "UnaryExpression") {
            throw throwError();
        }
        setParent(expr, node);
    }
    function throwOperatorError() {
        throw (0, errors_1.throwUnexpectedTokenError)(operator, tokens.getTokenAfter(tokens.getFirstToken(node), (t) => t.value === operator) || node);
    }
}
function isStaticValueIdentifier(node, ctx) {
    if (isNumberIdentifier(node, ctx)) {
        return true;
    }
    return node.name === "undefined" && ctx.undefinedKeywords;
}
exports.isStaticValueIdentifier = isStaticValueIdentifier;
function isNumberIdentifier(node, ctx) {
    if (node.name === "Infinity" && ctx.infinities) {
        return true;
    }
    if (node.name === "NaN" && ctx.nans) {
        return true;
    }
    return false;
}
function setParent(prop, parent) {
    prop.parent = parent;
}
