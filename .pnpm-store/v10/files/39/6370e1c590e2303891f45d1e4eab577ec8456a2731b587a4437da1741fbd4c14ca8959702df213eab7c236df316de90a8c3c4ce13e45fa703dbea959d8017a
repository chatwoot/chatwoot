"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.traverseNodes = exports.getNodes = exports.getKeys = exports.getFallbackKeys = void 0;
const visitor_keys_1 = require("./visitor-keys");
function fallbackKeysFilter(key) {
    let value = null;
    return (key !== "comments" &&
        key !== "leadingComments" &&
        key !== "loc" &&
        key !== "parent" &&
        key !== "range" &&
        key !== "tokens" &&
        key !== "trailingComments" &&
        (value = this[key]) !== null &&
        typeof value === "object" &&
        (typeof value.type === "string" || Array.isArray(value)));
}
function getFallbackKeys(node) {
    return Object.keys(node).filter(fallbackKeysFilter, node);
}
exports.getFallbackKeys = getFallbackKeys;
function getKeys(node, visitorKeys) {
    const keys = (visitorKeys || (0, visitor_keys_1.getVisitorKeys)())[node.type] || getFallbackKeys(node);
    return keys.filter((key) => !getNodes(node, key).next().done);
}
exports.getKeys = getKeys;
function* getNodes(node, key) {
    const child = node[key];
    if (Array.isArray(child)) {
        for (const c of child) {
            if (isNode(c)) {
                yield c;
            }
        }
    }
    else if (isNode(child)) {
        yield child;
    }
}
exports.getNodes = getNodes;
function isNode(x) {
    return x !== null && typeof x === "object" && typeof x.type === "string";
}
function traverse(node, parent, visitor) {
    visitor.enterNode(node, parent);
    const keys = getKeys(node, visitor.visitorKeys);
    for (const key of keys) {
        for (const child of getNodes(node, key)) {
            traverse(child, node, visitor);
        }
    }
    visitor.leaveNode(node, parent);
}
function traverseNodes(node, visitor) {
    traverse(node, null, visitor);
}
exports.traverseNodes = traverseNodes;
