"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// This module is suitable for passing as options.parser when calling
// recast.parse to process ECMAScript code with Esprima:
//
//   const ast = recast.parse(source, {
//     parser: require("recast/parsers/esprima")
//   });
//
var util_1 = require("../lib/util");
function parse(source, options) {
    var comments = [];
    var ast = require("esprima").parse(source, {
        loc: true,
        locations: true,
        comment: true,
        onComment: comments,
        range: util_1.getOption(options, "range", false),
        tolerant: util_1.getOption(options, "tolerant", true),
        tokens: true
    });
    if (!Array.isArray(ast.comments)) {
        ast.comments = comments;
    }
    return ast;
}
exports.parse = parse;
;
