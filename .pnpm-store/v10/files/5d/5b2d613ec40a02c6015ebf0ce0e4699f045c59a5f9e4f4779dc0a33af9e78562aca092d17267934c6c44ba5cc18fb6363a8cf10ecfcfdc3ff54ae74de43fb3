"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SET = void 0;
const utils_1 = require("../utils");
exports.SET = {
    // see https://yaml.org/type/set.html
    tag: "tag:yaml.org,2002:set",
    testNode(node) {
        return (node.type === "YAMLMapping" &&
            node.pairs.every((p) => p.key != null && p.value == null));
    },
    resolveNode(node) {
        const map = node;
        const result = [];
        for (const p of map.pairs) {
            result.push((0, utils_1.getStaticYAMLValue)(p.key));
        }
        return result;
    },
};
