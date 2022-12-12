"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isInterpolationNode = exports.isCompoundExpressionNode = exports.isSimpleExpressionNode = exports.isAttributeNode = exports.isDirectiveNode = exports.isBaseElementNode = exports.isCommentNode = exports.isTextNode = void 0;
function isTextNode(node) {
    return !!node && node.type === 2 /* TEXT */;
}
exports.isTextNode = isTextNode;
function isCommentNode(node) {
    return !!node && node.type === 3 /* COMMENT */;
}
exports.isCommentNode = isCommentNode;
function isBaseElementNode(node) {
    return !!node && node.type === 1 /* ELEMENT */;
}
exports.isBaseElementNode = isBaseElementNode;
function isDirectiveNode(prop) {
    return !!prop && prop.type === 7 /* DIRECTIVE */;
}
exports.isDirectiveNode = isDirectiveNode;
function isAttributeNode(prop) {
    return !!prop && prop.type === 6 /* ATTRIBUTE */;
}
exports.isAttributeNode = isAttributeNode;
function isSimpleExpressionNode(exp) {
    return !!exp && exp.type === 4 /* SIMPLE_EXPRESSION */;
}
exports.isSimpleExpressionNode = isSimpleExpressionNode;
function isCompoundExpressionNode(exp) {
    return !!exp && exp.type === 8 /* COMPOUND_EXPRESSION */;
}
exports.isCompoundExpressionNode = isCompoundExpressionNode;
function isInterpolationNode(exp) {
    return !!exp && exp.type === 5 /* INTERPOLATION */;
}
exports.isInterpolationNode = isInterpolationNode;
