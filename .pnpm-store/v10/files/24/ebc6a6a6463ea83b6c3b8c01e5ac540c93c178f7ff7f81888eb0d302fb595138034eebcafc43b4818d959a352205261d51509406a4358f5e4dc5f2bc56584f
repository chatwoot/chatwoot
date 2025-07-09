"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.traverseNode = void 0;
const utils_1 = require("./utils");
function traverseNodes(nodes, visit) {
    for (let i = 0; i < nodes.length; i++) {
        traverseNode(nodes[i], visit);
    }
}
function traverseNode(node, visit) {
    if (!node) {
        return;
    }
    visit(node);
    if (node.type === utils_1.NodeTypes.Resource) {
        traverseNode(node.body, visit);
    }
    else if (node.type === utils_1.NodeTypes.Plural) {
        traverseNodes(node.cases, visit);
    }
    else if (node.type === utils_1.NodeTypes.Message) {
        traverseNodes(node.items, visit);
    }
    else if (node.type === utils_1.NodeTypes.Linked) {
        const linked = node;
        if (linked.modifier)
            traverseNode(linked.modifier, visit);
        traverseNode(linked.key, visit);
    }
}
exports.traverseNode = traverseNode;
