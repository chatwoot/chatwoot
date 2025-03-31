"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseForESLint = void 0;
const visitor_keys_1 = require("./visitor-keys");
const convert_1 = require("./convert");
const context_1 = require("./context");
const yaml_cst_parse_1 = require("./yaml-cst-parse");
/**
 * Parse source code
 */
function parseForESLint(code, options) {
    const ctx = new context_1.Context(code, options);
    const docs = (0, yaml_cst_parse_1.parseAllDocsToCST)(ctx);
    const ast = (0, convert_1.convertRoot)(docs, ctx);
    return {
        ast,
        visitorKeys: visitor_keys_1.KEYS,
        services: {
            isYAML: true,
        },
    };
}
exports.parseForESLint = parseForESLint;
