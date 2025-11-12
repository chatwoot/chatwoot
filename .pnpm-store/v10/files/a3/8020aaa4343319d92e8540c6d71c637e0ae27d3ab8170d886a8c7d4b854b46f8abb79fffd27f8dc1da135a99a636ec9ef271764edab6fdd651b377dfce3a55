"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const node_path_1 = require("node:path");
const debug_1 = __importDefault(require("debug"));
const index_1 = require("../utils/index");
const utils_1 = require("../utils/message-compiler/utils");
const parser_1 = require("../utils/message-compiler/parser");
const traverser_1 = require("../utils/message-compiler/traverser");
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-deprecated-modulo-syntax');
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
            if (node.type !== utils_1.NodeTypes.Named || !node.modulo) {
                return;
            }
            let range = null;
            const start = getReportOffset(node.loc.start.offset);
            const end = getReportOffset(node.loc.end.offset);
            if (start != null && end != null) {
                range = [start - 1, end];
            }
            context.report({
                loc: range
                    ? {
                        start: sourceCode.getLocFromIndex(range[0]),
                        end: sourceCode.getLocFromIndex(range[1])
                    }
                    : reportNode.loc,
                message: 'The modulo interpolation must be enforced to named interpolation.',
                fix(fixer) {
                    return range ? fixer.removeRange([range[0], range[0] + 1]) : null;
                }
            });
        });
    }
    function verifyMessage(message, reportNode, getReportOffset) {
        if (messageSyntaxVersions.reportIfMissingSetting()) {
            return;
        }
        if (messageSyntaxVersions.v9) {
            verifyForV9(message, reportNode, getReportOffset);
        }
        else if (messageSyntaxVersions.v8) {
            return;
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
            debug(`ignore ${filename} in no-deprecated-modulo-syntax`);
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
        debug(`ignore ${filename} in no-deprecated-modulo-syntax`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'enforce modulo interpolation to be named interpolation',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-deprecated-modulo-syntax.html',
            recommended: true
        },
        fixable: 'code',
        schema: []
    },
    create
});
