"use strict";;
Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_operators_1 = require("./core-operators");
var es2019_1 = tslib_1.__importDefault(require("./es2019"));
var types_1 = tslib_1.__importDefault(require("../lib/types"));
var shared_1 = tslib_1.__importDefault(require("../lib/shared"));
function default_1(fork) {
    fork.use(es2019_1.default);
    var types = fork.use(types_1.default);
    var def = types.Type.def;
    var or = types.Type.or;
    var shared = fork.use(shared_1.default);
    var defaults = shared.defaults;
    def("ImportExpression")
        .bases("Expression")
        .build("source")
        .field("source", def("Expression"));
    def("ExportAllDeclaration")
        .build("source", "exported")
        .field("source", def("Literal"))
        .field("exported", or(def("Identifier"), null));
    // Optional chaining
    def("ChainElement")
        .bases("Node")
        .field("optional", Boolean, defaults["false"]);
    def("CallExpression")
        .bases("Expression", "ChainElement");
    def("MemberExpression")
        .bases("Expression", "ChainElement");
    def("ChainExpression")
        .bases("Expression")
        .build("expression")
        .field("expression", def("ChainElement"));
    def("OptionalCallExpression")
        .bases("CallExpression")
        .build("callee", "arguments", "optional")
        .field("optional", Boolean, defaults["true"]);
    // Deprecated optional chaining type, doesn't work with babelParser@7.11.0 or newer
    def("OptionalMemberExpression")
        .bases("MemberExpression")
        .build("object", "property", "computed", "optional")
        .field("optional", Boolean, defaults["true"]);
    // Nullish coalescing
    var LogicalOperator = or.apply(void 0, tslib_1.__spreadArrays(core_operators_1.LogicalOperators, ["??"]));
    def("LogicalExpression")
        .field("operator", LogicalOperator);
}
exports.default = default_1;
module.exports = exports["default"];
