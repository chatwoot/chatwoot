"use strict";;
Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var core_operators_1 = require("./core-operators");
var es6_1 = tslib_1.__importDefault(require("./es6"));
var types_1 = tslib_1.__importDefault(require("../lib/types"));
function default_1(fork) {
    fork.use(es6_1.default);
    var types = fork.use(types_1.default);
    var def = types.Type.def;
    var or = types.Type.or;
    var BinaryOperator = or.apply(void 0, tslib_1.__spreadArrays(core_operators_1.BinaryOperators, ["**"]));
    def("BinaryExpression")
        .field("operator", BinaryOperator);
    var AssignmentOperator = or.apply(void 0, tslib_1.__spreadArrays(core_operators_1.AssignmentOperators, ["**="]));
    def("AssignmentExpression")
        .field("operator", AssignmentOperator);
}
exports.default = default_1;
module.exports = exports["default"];
