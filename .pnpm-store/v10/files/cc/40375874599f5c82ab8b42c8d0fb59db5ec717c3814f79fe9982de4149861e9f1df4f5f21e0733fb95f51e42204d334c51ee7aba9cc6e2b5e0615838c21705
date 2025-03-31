"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OMAP = void 0;
const utils_1 = require("../utils");
exports.OMAP = {
    // see https://yaml.org/type/omap.html
    tag: "tag:yaml.org,2002:omap",
    testNode(node) {
        return (node.type === "YAMLSequence" &&
            node.entries.every((e) => (e === null || e === void 0 ? void 0 : e.type) === "YAMLMapping" && e.pairs.length === 1));
    },
    resolveNode(node) {
        const seq = node;
        const result = {};
        for (const e of seq.entries) {
            const map = e;
            for (const p of map.pairs) {
                const key = p.key ? (0, utils_1.getStaticYAMLValue)(p.key) : p.key;
                const value = p.value ? (0, utils_1.getStaticYAMLValue)(p.value) : p.value;
                result[key] = value;
            }
        }
        return result;
    },
};
