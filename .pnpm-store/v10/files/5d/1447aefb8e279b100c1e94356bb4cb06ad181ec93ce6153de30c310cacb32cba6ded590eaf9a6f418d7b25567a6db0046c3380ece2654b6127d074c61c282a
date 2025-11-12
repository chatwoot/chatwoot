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
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseJSON = exports.isUndefinedIdentifier = exports.isNumberIdentifier = exports.isExpression = exports.getStaticJSONValue = exports.traverseNodes = exports.VisitorKeys = exports.parseForESLint = exports.name = exports.meta = void 0;
const parser_1 = require("./parser/parser");
Object.defineProperty(exports, "parseForESLint", { enumerable: true, get: function () { return parser_1.parseForESLint; } });
const traverse_1 = require("./parser/traverse");
Object.defineProperty(exports, "traverseNodes", { enumerable: true, get: function () { return traverse_1.traverseNodes; } });
const ast_1 = require("./utils/ast");
Object.defineProperty(exports, "getStaticJSONValue", { enumerable: true, get: function () { return ast_1.getStaticJSONValue; } });
Object.defineProperty(exports, "isExpression", { enumerable: true, get: function () { return ast_1.isExpression; } });
Object.defineProperty(exports, "isNumberIdentifier", { enumerable: true, get: function () { return ast_1.isNumberIdentifier; } });
Object.defineProperty(exports, "isUndefinedIdentifier", { enumerable: true, get: function () { return ast_1.isUndefinedIdentifier; } });
const visitor_keys_1 = require("./parser/visitor-keys");
exports.meta = __importStar(require("./meta"));
var meta_1 = require("./meta");
Object.defineProperty(exports, "name", { enumerable: true, get: function () { return meta_1.name; } });
exports.VisitorKeys = (0, visitor_keys_1.getVisitorKeys)();
function parseJSON(code, options) {
    return (0, parser_1.parseForESLint)(code, options).ast;
}
exports.parseJSON = parseJSON;
