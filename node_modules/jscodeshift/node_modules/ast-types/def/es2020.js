"use strict";;
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var es7_1 = __importDefault(require("./es7"));
var types_1 = __importDefault(require("../lib/types"));
function default_1(fork) {
    fork.use(es7_1.default);
    var types = fork.use(types_1.default);
    var def = types.Type.def;
    def("ImportExpression")
        .bases("Expression")
        .build("source")
        .field("source", def("Expression"));
}
exports.default = default_1;
module.exports = exports["default"];
