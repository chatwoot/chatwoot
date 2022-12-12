"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var babel_1 = require("./babel");
var _babel_options_1 = __importDefault(require("./_babel_options"));
// This module is suitable for passing as options.parser when calling
// recast.parse to process TypeScript code:
//
//   const ast = recast.parse(source, {
//     parser: require("recast/parsers/typescript")
//   });
//
function parse(source, options) {
    var babelOptions = _babel_options_1.default(options);
    babelOptions.plugins.push("typescript");
    return babel_1.parser.parse(source, babelOptions);
}
exports.parse = parse;
;
