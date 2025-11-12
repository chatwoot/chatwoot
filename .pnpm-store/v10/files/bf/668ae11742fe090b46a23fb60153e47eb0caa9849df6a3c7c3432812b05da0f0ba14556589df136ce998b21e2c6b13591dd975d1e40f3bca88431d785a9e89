"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defineCreateVisitorForYaml = exports.defineCreateVisitorForJson = exports.createRule = void 0;
const utils_1 = require("../utils/message-compiler/utils");
function createRule(module) {
    return module;
}
exports.createRule = createRule;
function defineCreateVisitorForJson(verifyMessage) {
    return function () {
        function verifyExpression(node) {
            if (node.type !== 'JSONLiteral' || typeof node.value !== 'string') {
                return;
            }
            verifyMessage(node.value, node, offset => (0, utils_1.getReportIndex)(node, offset));
        }
        return {
            JSONProperty(node) {
                verifyExpression(node.value);
            },
            JSONArrayExpression(node) {
                for (const element of node.elements) {
                    if (element)
                        verifyExpression(element);
                }
            }
        };
    };
}
exports.defineCreateVisitorForJson = defineCreateVisitorForJson;
function defineCreateVisitorForYaml(verifyMessage) {
    return function () {
        const yamlKeyNodes = new Set();
        function withinKey(node) {
            for (const keyNode of yamlKeyNodes) {
                if (keyNode.range[0] <= node.range[0] &&
                    node.range[0] < keyNode.range[1]) {
                    return true;
                }
            }
            return false;
        }
        function verifyContent(node) {
            const valueNode = node.type === 'YAMLWithMeta' ? node.value : node;
            if (!valueNode ||
                valueNode.type !== 'YAMLScalar' ||
                typeof valueNode.value !== 'string') {
                return;
            }
            verifyMessage(valueNode.value, valueNode, offset => (0, utils_1.getReportIndex)(valueNode, offset));
        }
        return {
            YAMLPair(node) {
                if (withinKey(node)) {
                    return;
                }
                if (node.key != null) {
                    yamlKeyNodes.add(node.key);
                }
                if (node.value)
                    verifyContent(node.value);
            },
            YAMLSequence(node) {
                if (withinKey(node)) {
                    return;
                }
                for (const entry of node.entries) {
                    if (entry)
                        verifyContent(entry);
                }
            }
        };
    };
}
exports.defineCreateVisitorForYaml = defineCreateVisitorForYaml;
