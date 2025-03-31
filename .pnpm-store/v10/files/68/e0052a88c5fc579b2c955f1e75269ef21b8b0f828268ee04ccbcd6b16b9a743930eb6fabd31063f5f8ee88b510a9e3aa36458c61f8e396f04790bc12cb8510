"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const jsonc_eslint_parser_1 = require("jsonc-eslint-parser");
const yaml_eslint_parser_1 = require("yaml-eslint-parser");
const path_1 = require("path");
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const utils_1 = require("../utils/message-compiler/utils");
const parser_1 = require("../utils/message-compiler/parser");
const parser_v8_1 = require("../utils/message-compiler/parser-v8");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:valid-message-syntax');
function create(context) {
    var _a;
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const allowNotString = Boolean((_a = context.options[0]) === null || _a === void 0 ? void 0 : _a.allowNotString);
    const messageSyntaxVersions = (0, utils_1.getMessageSyntaxVersions)(context);
    function* extractMessageErrors(message) {
        if (messageSyntaxVersions.v9) {
            yield* (0, parser_1.parse)(message).errors;
        }
        if (messageSyntaxVersions.v8) {
            yield* (0, parser_v8_1.parse)(message).errors;
        }
    }
    function verifyMessage(message, reportNode, getReportOffset) {
        if (typeof message !== 'string') {
            if (!allowNotString) {
                const type = message === null
                    ? 'null'
                    : message instanceof RegExp
                        ? 'RegExp'
                        : typeof message;
                context.report({
                    message: `Unexpected '${type}' message`,
                    loc: reportNode.loc
                });
            }
        }
        else {
            for (const error of extractMessageErrors(message)) {
                messageSyntaxVersions.reportIfMissingSetting();
                const reportOffset = getReportOffset === null || getReportOffset === void 0 ? void 0 : getReportOffset(error);
                context.report({
                    message: error.message,
                    loc: reportOffset != null
                        ? sourceCode.getLocFromIndex(reportOffset)
                        : reportNode.loc
                });
            }
        }
    }
    function createVisitorForJson() {
        function verifyExpression(node, parent) {
            let message;
            let getReportOffset = null;
            if (node) {
                if (node.type === 'JSONArrayExpression' ||
                    node.type === 'JSONObjectExpression') {
                    return;
                }
                message = (0, jsonc_eslint_parser_1.getStaticJSONValue)(node);
                getReportOffset = error => (0, utils_1.getReportIndex)(node, error.location.start.offset);
            }
            else {
                message = null;
            }
            verifyMessage(message, node || parent, getReportOffset);
        }
        return {
            JSONProperty(node) {
                verifyExpression(node.value, node);
            },
            JSONArrayExpression(node) {
                for (const element of node.elements) {
                    verifyExpression(element, node);
                }
            }
        };
    }
    function createVisitorForYaml() {
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
        function verifyContent(node, parent) {
            let message;
            let getReportOffset = null;
            if (node) {
                const valueNode = node.type === 'YAMLWithMeta' ? node.value : node;
                if (!valueNode ||
                    valueNode.type === 'YAMLMapping' ||
                    valueNode.type === 'YAMLSequence') {
                    return;
                }
                message = (0, yaml_eslint_parser_1.getStaticYAMLValue)(node);
                getReportOffset = error => (0, utils_1.getReportIndex)(valueNode, error.location.start.offset);
            }
            else {
                message = null;
            }
            if (message != null && typeof message === 'object') {
                return;
            }
            verifyMessage(message, node || parent, getReportOffset);
        }
        return {
            YAMLPair(node) {
                if (withinKey(node)) {
                    return;
                }
                if (node.key != null) {
                    yamlKeyNodes.add(node.key);
                }
                verifyContent(node.value, node);
            },
            YAMLSequence(node) {
                if (withinKey(node)) {
                    return;
                }
                for (const entry of node.entries) {
                    verifyContent(entry, node);
                }
            }
        };
    }
    if ((0, path_1.extname)(filename) === '.vue') {
        return (0, index_1.defineCustomBlocksVisitor)(context, createVisitorForJson, createVisitorForYaml);
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in valid-message-syntax`);
            return {};
        }
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson();
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml();
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in valid-message-syntax`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'layout',
        docs: {
            description: 'disallow invalid message syntax',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/valid-message-syntax.html',
            recommended: true
        },
        fixable: null,
        schema: [
            {
                type: 'object',
                properties: {
                    allowNotString: {
                        type: 'boolean'
                    }
                },
                additionalProperties: false
            }
        ]
    },
    create
});
