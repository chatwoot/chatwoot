"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs_1 = __importDefault(require("fs"));
var types = __importStar(require("ast-types"));
exports.types = types;
var parser_1 = require("./lib/parser");
exports.parse = parser_1.parse;
var printer_1 = require("./lib/printer");
/**
 * Traverse and potentially modify an abstract syntax tree using a
 * convenient visitor syntax:
 *
 *   recast.visit(ast, {
 *     names: [],
 *     visitIdentifier: function(path) {
 *       var node = path.value;
 *       this.visitor.names.push(node.name);
 *       this.traverse(path);
 *     }
 *   });
 */
var ast_types_1 = require("ast-types");
exports.visit = ast_types_1.visit;
/**
 * Reprint a modified syntax tree using as much of the original source
 * code as possible.
 */
function print(node, options) {
    return new printer_1.Printer(options).print(node);
}
exports.print = print;
/**
 * Print without attempting to reuse any original source code.
 */
function prettyPrint(node, options) {
    return new printer_1.Printer(options).printGenerically(node);
}
exports.prettyPrint = prettyPrint;
/**
 * Convenient command-line interface (see e.g. example/add-braces).
 */
function run(transformer, options) {
    return runFile(process.argv[2], transformer, options);
}
exports.run = run;
function runFile(path, transformer, options) {
    fs_1.default.readFile(path, "utf-8", function (err, code) {
        if (err) {
            console.error(err);
            return;
        }
        runString(code, transformer, options);
    });
}
function defaultWriteback(output) {
    process.stdout.write(output);
}
function runString(code, transformer, options) {
    var writeback = options && options.writeback || defaultWriteback;
    transformer(parser_1.parse(code, options), function (node) {
        writeback(print(node, options).code);
    });
}
