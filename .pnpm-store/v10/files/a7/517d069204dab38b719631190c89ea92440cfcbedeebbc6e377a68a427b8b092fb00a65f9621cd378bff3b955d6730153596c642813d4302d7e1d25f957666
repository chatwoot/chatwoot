"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getVisitorKeys = void 0;
const require_utils_1 = require("./modules/require-utils");
const jsonKeys = {
    Program: ["body"],
    JSONExpressionStatement: ["expression"],
    JSONArrayExpression: ["elements"],
    JSONObjectExpression: ["properties"],
    JSONProperty: ["key", "value"],
    JSONIdentifier: [],
    JSONLiteral: [],
    JSONUnaryExpression: ["argument"],
    JSONTemplateLiteral: ["quasis", "expressions"],
    JSONTemplateElement: [],
    JSONBinaryExpression: ["left", "right"],
};
let cache = null;
function getVisitorKeys() {
    if (!cache) {
        const vk = (0, require_utils_1.loadNewest)([
            {
                getPkg() {
                    return (0, require_utils_1.requireFromCwd)("eslint-visitor-keys/package.json");
                },
                get() {
                    return (0, require_utils_1.requireFromCwd)("eslint-visitor-keys");
                },
            },
            {
                getPkg() {
                    return (0, require_utils_1.requireFromLinter)("eslint-visitor-keys/package.json");
                },
                get() {
                    return (0, require_utils_1.requireFromLinter)("eslint-visitor-keys");
                },
            },
            {
                getPkg() {
                    return require("eslint-visitor-keys/package.json");
                },
                get() {
                    return require("eslint-visitor-keys");
                },
            },
        ]);
        cache = vk.unionWith(jsonKeys);
    }
    return cache;
}
exports.getVisitorKeys = getVisitorKeys;
