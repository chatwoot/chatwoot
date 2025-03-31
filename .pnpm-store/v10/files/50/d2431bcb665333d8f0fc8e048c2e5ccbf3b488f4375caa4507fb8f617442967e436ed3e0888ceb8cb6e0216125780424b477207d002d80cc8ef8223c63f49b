"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseYamlValuesInI18nBlock = exports.parseJsonValuesInI18nBlock = void 0;
const json5_1 = require("json5");
const js_yaml_1 = require("js-yaml");
function hasEndTag(element) {
    return !!element.endTag;
}
function parseValuesInI18nBlock(i18nBlock, parse) {
    if (!hasEndTag(i18nBlock)) {
        return null;
    }
    const text = i18nBlock.children[0];
    const sourceString = text != null && text.type === 'VText' ? text.value : '';
    if (!sourceString.trim()) {
        return null;
    }
    try {
        return parse(sourceString);
    }
    catch (e) {
        return null;
    }
}
function parseJsonValuesInI18nBlock(i18nBlock) {
    return parseValuesInI18nBlock(i18nBlock, code => (0, json5_1.parse)(code));
}
exports.parseJsonValuesInI18nBlock = parseJsonValuesInI18nBlock;
function parseYamlValuesInI18nBlock(i18nBlock) {
    return parseValuesInI18nBlock(i18nBlock, code => (0, js_yaml_1.load)(code));
}
exports.parseYamlValuesInI18nBlock = parseYamlValuesInI18nBlock;
