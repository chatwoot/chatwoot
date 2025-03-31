"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const node_path_1 = require("node:path");
const debug_1 = __importDefault(require("debug"));
const rule_1 = require("../utils/rule");
const index_1 = require("../utils/index");
const utils_1 = require("../utils/message-compiler/utils");
const parser_1 = require("../utils/message-compiler/parser");
const parser_v8_1 = require("../utils/message-compiler/parser-v8");
const traverser_1 = require("../utils/message-compiler/traverser");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:prefer-linked-key-with-paren');
function getSingleQuote(node) {
    if (node.type === 'JSONLiteral') {
        return node.raw[0] !== "'" ? "'" : "\\'";
    }
    if (node.style === 'single-quoted') {
        return "''";
    }
    return "'";
}
function create(context) {
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    const messageSyntaxVersions = (0, utils_1.getMessageSyntaxVersions)(context);
    function verifyForV9(message, reportNode, getReportOffset) {
        const { ast, errors } = (0, parser_1.parse)(message);
        if (errors.length) {
            return;
        }
        (0, traverser_1.traverseNode)(ast, node => {
            if (node.type !== utils_1.NodeTypes.LinkedKey) {
                return;
            }
            let range = null;
            const start = getReportOffset(node.loc.start.offset);
            const end = getReportOffset(node.loc.end.offset);
            if (start != null && end != null) {
                range = [start, end];
            }
            context.report({
                loc: range
                    ? {
                        start: sourceCode.getLocFromIndex(range[0]),
                        end: sourceCode.getLocFromIndex(range[1])
                    }
                    : reportNode.loc,
                message: 'The linked message key must be enclosed in brackets.',
                fix(fixer) {
                    if (!range) {
                        return null;
                    }
                    const single = getSingleQuote(reportNode);
                    return [
                        fixer.insertTextBeforeRange(range, `{${single}`),
                        fixer.insertTextAfterRange(range, `${single}}`)
                    ];
                }
            });
        });
    }
    function verifyForV8(message, reportNode, getReportOffset) {
        const { ast, errors } = (0, parser_v8_1.parse)(message);
        if (errors.length) {
            return;
        }
        (0, traverser_1.traverseNode)(ast, node => {
            if (node.type !== utils_1.NodeTypes.LinkedKey) {
                return;
            }
            if (message[node.loc.start.offset - 1] === '(') {
                return;
            }
            let range = null;
            const start = getReportOffset(node.loc.start.offset);
            const end = getReportOffset(node.loc.end.offset);
            if (start != null && end != null) {
                range = [start, end];
            }
            context.report({
                loc: range
                    ? {
                        start: sourceCode.getLocFromIndex(range[0]),
                        end: sourceCode.getLocFromIndex(range[1])
                    }
                    : reportNode.loc,
                message: 'The linked message key must be enclosed in parentheses.',
                fix(fixer) {
                    if (!range) {
                        return null;
                    }
                    return [
                        fixer.insertTextBeforeRange(range, '('),
                        fixer.insertTextAfterRange(range, ')')
                    ];
                }
            });
        });
    }
    function verifyMessage(message, reportNode, getReportOffset) {
        if (messageSyntaxVersions.reportIfMissingSetting()) {
            return;
        }
        if (messageSyntaxVersions.v9 && messageSyntaxVersions.v8) {
            return;
        }
        if (messageSyntaxVersions.v9) {
            verifyForV9(message, reportNode, getReportOffset);
        }
        else if (messageSyntaxVersions.v8) {
            verifyForV8(message, reportNode, getReportOffset);
        }
    }
    const createVisitorForJson = (0, rule_1.defineCreateVisitorForJson)(verifyMessage);
    const createVisitorForYaml = (0, rule_1.defineCreateVisitorForYaml)(verifyMessage);
    if ((0, node_path_1.extname)(filename) === '.vue') {
        return (0, index_1.defineCustomBlocksVisitor)(context, createVisitorForJson, createVisitorForYaml);
    }
    else if (sourceCode.parserServices.isJSON ||
        sourceCode.parserServices.isYAML) {
        const localeMessages = (0, index_1.getLocaleMessages)(context);
        const targetLocaleMessage = localeMessages.findExistLocaleMessage(filename);
        if (!targetLocaleMessage) {
            debug(`ignore ${filename} in prefer-linked-key-with-paren`);
            return {};
        }
        if (sourceCode.parserServices.isJSON) {
            return createVisitorForJson(context);
        }
        else if (sourceCode.parserServices.isYAML) {
            return createVisitorForYaml(context);
        }
        return {};
    }
    else {
        debug(`ignore ${filename} in prefer-linked-key-with-paren`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'layout',
        docs: {
            description: 'enforce linked key to be enclosed in parentheses',
            category: 'Stylistic Issues',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/prefer-linked-key-with-paren.html',
            recommended: false
        },
        fixable: 'code',
        schema: []
    },
    create
});
