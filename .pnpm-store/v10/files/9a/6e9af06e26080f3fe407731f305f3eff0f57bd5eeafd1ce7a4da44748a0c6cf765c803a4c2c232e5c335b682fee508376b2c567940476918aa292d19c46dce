"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseByParser = void 0;
const fs_1 = require("fs");
const path_1 = __importDefault(require("path"));
const vue_eslint_parser_1 = require("vue-eslint-parser");
function parseByParser(filePath, parserDefine, parserOptions) {
    const parser = getParser(parserDefine, filePath);
    try {
        const text = (0, fs_1.readFileSync)(path_1.default.resolve(filePath), 'utf8');
        const parseResult = 'parseForESLint' in parser && typeof parser.parseForESLint === 'function'
            ? parser.parseForESLint(text, parserOptions)
            :
                { ast: parser.parse(text, parserOptions) };
        return parseResult;
    }
    catch (_e) {
        return null;
    }
}
exports.parseByParser = parseByParser;
function getParser(parser, filePath) {
    if (parser) {
        if (typeof parser === 'string') {
            try {
                return require(parser);
            }
            catch (_e) {
            }
        }
        else {
            return parser;
        }
    }
    if (filePath.endsWith('.vue')) {
        return { parseForESLint: vue_eslint_parser_1.parseForESLint };
    }
    return require('espree');
}
