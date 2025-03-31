"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.collectLinkedKeys = void 0;
const traverser_1 = require("./message-compiler/traverser");
const parser_1 = require("./message-compiler/parser");
const parser_v8_1 = require("./message-compiler/parser-v8");
const utils_1 = require("./message-compiler/utils");
const utils_2 = require("./message-compiler/utils");
function* extractUsedKeysFromLinks(object, messageSyntaxVersions) {
    for (const value of Object.values(object)) {
        if (!value) {
            continue;
        }
        if (typeof value === 'object') {
            yield* extractUsedKeysFromLinks(value, messageSyntaxVersions);
        }
        else if (typeof value === 'string') {
            if (messageSyntaxVersions.v9) {
                yield* extractUsedKeysFromAST((0, parser_1.parse)(value).ast);
            }
            if (messageSyntaxVersions.v8) {
                yield* extractUsedKeysFromAST((0, parser_v8_1.parse)(value).ast);
            }
        }
    }
}
function collectLinkedKeys(object, context) {
    return [
        ...new Set(extractUsedKeysFromLinks(object, (0, utils_2.getMessageSyntaxVersions)(context)))
    ].filter(s => !!s);
}
exports.collectLinkedKeys = collectLinkedKeys;
function extractUsedKeysFromAST(ast) {
    const keys = new Set();
    (0, traverser_1.traverseNode)(ast, node => {
        if (node.type === utils_1.NodeTypes.Linked) {
            if (node.key.type === utils_1.NodeTypes.LinkedKey) {
                keys.add(node.key.value);
            }
            else if (node.key.type === utils_1.NodeTypes.Literal && node.key.value) {
                keys.add(node.key.value);
            }
            else if (node.key.type === utils_1.NodeTypes.List) {
                keys.add(String(node.key.index));
            }
        }
    });
    return keys;
}
