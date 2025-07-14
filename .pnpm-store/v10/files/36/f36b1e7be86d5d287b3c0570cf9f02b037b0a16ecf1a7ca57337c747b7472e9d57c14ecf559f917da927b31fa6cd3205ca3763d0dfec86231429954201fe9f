"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const path_1 = require("path");
const parse5 = __importStar(require("parse5"));
const index_1 = require("../utils/index");
const debug_1 = __importDefault(require("debug"));
const rule_1 = require("../utils/rule");
const compat_1 = require("../utils/compat");
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:no-html-messages');
function findHTMLNode(node) {
    return node.childNodes.find((child) => {
        if (child.nodeName !== '#text' && child.tagName) {
            return true;
        }
        return false;
    });
}
function create(context) {
    const filename = (0, compat_1.getFilename)(context);
    const sourceCode = (0, compat_1.getSourceCode)(context);
    function verifyJSONLiteral(node) {
        const parent = node.parent;
        if (parent.type === 'JSONProperty' && parent.key === node) {
            return;
        }
        const htmlNode = parse5.parseFragment(`${node.value}`, {
            sourceCodeLocationInfo: true
        });
        const foundNode = findHTMLNode(htmlNode);
        if (!foundNode) {
            return;
        }
        const loc = {
            line: node.loc.start.line,
            column: node.loc.start.column +
                1 +
                foundNode.sourceCodeLocation.startOffset
        };
        context.report({
            message: `used HTML localization message`,
            loc
        });
    }
    function verifyYAMLScalar(node) {
        const parent = node.parent;
        if (parent.type === 'YAMLPair' && parent.key === node) {
            return;
        }
        const htmlNode = parse5.parseFragment(`${node.value}`, {
            sourceCodeLocationInfo: true
        });
        const foundNode = findHTMLNode(htmlNode);
        if (!foundNode) {
            return;
        }
        const loc = {
            line: node.loc.start.line,
            column: node.loc.start.column +
                1 +
                foundNode.sourceCodeLocation.startOffset
        };
        context.report({
            message: `used HTML localization message`,
            loc
        });
    }
    if ((0, path_1.extname)(filename) === '.vue') {
        return (0, index_1.defineCustomBlocksVisitor)(context, () => {
            return {
                JSONLiteral: verifyJSONLiteral
            };
        }, () => {
            return {
                YAMLScalar: verifyYAMLScalar
            };
        });
    }
    else if (sourceCode.parserServices.isJSON) {
        if (!(0, index_1.getLocaleMessages)(context).findExistLocaleMessage(filename)) {
            return {};
        }
        return {
            JSONLiteral: verifyJSONLiteral
        };
    }
    else if (sourceCode.parserServices.isYAML) {
        if (!(0, index_1.getLocaleMessages)(context).findExistLocaleMessage(filename)) {
            return {};
        }
        return {
            YAMLScalar: verifyYAMLScalar
        };
    }
    else {
        debug(`ignore ${filename} in no-html-messages`);
        return {};
    }
}
module.exports = (0, rule_1.createRule)({
    meta: {
        type: 'problem',
        docs: {
            description: 'disallow use HTML localization messages',
            category: 'Recommended',
            url: 'https://eslint-plugin-vue-i18n.intlify.dev/rules/no-html-messages.html',
            recommended: true
        },
        fixable: null,
        schema: []
    },
    create
});
