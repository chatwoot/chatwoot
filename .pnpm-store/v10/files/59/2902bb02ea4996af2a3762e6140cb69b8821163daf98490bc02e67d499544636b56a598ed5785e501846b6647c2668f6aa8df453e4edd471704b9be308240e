"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getStaticYAMLValue = void 0;
const yaml_1 = require("yaml");
const tags_1 = require("./tags");
/**
 * Gets the static value for the given node.
 */
function getStaticYAMLValue(node) {
    return getValue(node, null);
}
exports.getStaticYAMLValue = getStaticYAMLValue;
/**
 * Gets the static value for the given node with YAML version.
 */
function getValue(node, version) {
    return resolver[node.type](node, version);
}
const resolver = {
    Program(node) {
        return node.body.length === 0
            ? null
            : node.body.length === 1
                ? // eslint-disable-next-line new-cap -- traverse key
                    resolver.YAMLDocument(node.body[0])
                : // eslint-disable-next-line new-cap -- traverse key
                    node.body.map((n) => resolver.YAMLDocument(n));
    },
    YAMLDocument(node) {
        return node.content ? getValue(node.content, node.version) : null;
    },
    YAMLMapping(node, version) {
        const result = {};
        for (const pair of node.pairs) {
            Object.assign(result, getValue(pair, version));
        }
        return result;
    },
    YAMLPair(node, version) {
        const result = {};
        let key = node.key ? getValue(node.key, version) : null;
        if (typeof key !== "string" && typeof key !== "number") {
            key = String(key);
        }
        result[key] = node.value ? getValue(node.value, version) : null;
        return result;
    },
    YAMLSequence(node, version) {
        const result = [];
        for (const entry of node.entries) {
            result.push(entry ? getValue(entry, version) : null);
        }
        return result;
    },
    YAMLScalar(node) {
        return node.value;
    },
    YAMLAlias(node, version) {
        const anchor = findAnchor(node);
        return anchor ? getValue(anchor.parent, version) : null;
    },
    YAMLWithMeta(node, version) {
        if (node.tag) {
            const value = node.value;
            if (value == null) {
                return getTaggedValue(node.tag, "", "", version);
            }
            if (value.type === "YAMLScalar") {
                if (value.style === "plain") {
                    return getTaggedValue(node.tag, value.strValue, value.strValue, version);
                }
                if (value.style === "double-quoted" ||
                    value.style === "single-quoted") {
                    return getTaggedValue(node.tag, value.raw, value.strValue, version);
                }
            }
            for (const tagResolver of tags_1.tagNodeResolvers[version || "1.2"]) {
                if (tagResolver.tag === node.tag.tag && tagResolver.testNode(value)) {
                    return tagResolver.resolveNode(value);
                }
            }
        }
        if (node.value == null) {
            return null;
        }
        return getValue(node.value, version);
    },
};
/**
 * Find Anchor
 */
function findAnchor(node) {
    let p = node.parent;
    let doc = null;
    while (p) {
        if (p.type === "YAMLDocument") {
            doc = p;
            break;
        }
        p = p.parent;
    }
    const anchors = doc.anchors[node.name];
    if (!anchors) {
        return null;
    }
    let target = {
        anchor: null,
        distance: Infinity,
    };
    for (const anchor of anchors) {
        if (anchor.range[0] < node.range[0]) {
            const distance = node.range[0] - anchor.range[0];
            if (target.distance >= distance) {
                target = {
                    anchor,
                    distance,
                };
            }
        }
    }
    return target.anchor;
}
/**
 * Get tagged value
 */
function getTaggedValue(tag, text, str, version) {
    for (const tagResolver of tags_1.tagResolvers[version || "1.2"]) {
        if (tagResolver.tag === tag.tag && tagResolver.testString(str)) {
            return tagResolver.resolveString(str);
        }
    }
    const tagText = tag.tag.startsWith("!") ? tag.tag : `!<${tag.tag}>`;
    const value = (0, yaml_1.parseDocument)(`${version ? `%YAML ${version}` : ""}
---
${tagText} ${text}`).toJSON();
    return value;
}
