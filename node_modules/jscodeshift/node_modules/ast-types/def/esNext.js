"use strict";;
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var es6_1 = __importDefault(require("./es6"));
var types_1 = __importDefault(require("../lib/types"));
var shared_1 = __importDefault(require("../lib/shared"));
function default_1(fork) {
    fork.use(es6_1.default);
    var types = fork.use(types_1.default);
    var def = types.Type.def;
    var or = types.Type.or;
    var defaults = fork.use(shared_1.default).defaults;
    def("SpreadProperty")
        .bases("Node")
        .build("argument")
        .field("argument", def("Expression"));
    def("ObjectExpression")
        .field("properties", [or(def("Property"), def("SpreadProperty"), def("SpreadElement"))]);
    def("SpreadPropertyPattern")
        .bases("Pattern")
        .build("argument")
        .field("argument", def("Pattern"));
    def("ObjectPattern")
        .field("properties", [or(def("Property"), def("PropertyPattern"), def("SpreadPropertyPattern"))]);
    def("Function")
        .field("async", Boolean, defaults["false"]);
    def("AwaitExpression")
        .bases("Expression")
        .build("argument", "all")
        .field("argument", or(def("Expression"), null))
        .field("all", Boolean, defaults["false"]);
    // Dynamic import(stringExpression)
    def("ImportExpression")
        .bases("Expression")
        .build("source")
        .field("source", def("Expression"));
    // https://github.com/tc39/proposal-optional-chaining
    // `a?.b` as per https://github.com/estree/estree/issues/146
    def("OptionalMemberExpression")
        .bases("MemberExpression")
        .build("object", "property", "computed", "optional")
        .field("optional", Boolean, defaults["true"]);
    // a?.b()
    def("OptionalCallExpression")
        .bases("CallExpression")
        .build("callee", "arguments", "optional")
        .field("optional", Boolean, defaults["true"]);
    // https://github.com/tc39/proposal-nullish-coalescing
    // `a ?? b` as per https://github.com/babel/babylon/pull/761/files
    var LogicalOperator = or("||", "&&", "??");
    def("LogicalExpression")
        .field("operator", LogicalOperator);
}
exports.default = default_1;
module.exports = exports["default"];
