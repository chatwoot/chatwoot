"use strict";;
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var babel_core_1 = __importDefault(require("./babel-core"));
var flow_1 = __importDefault(require("./flow"));
function default_1(fork) {
    fork.use(babel_core_1.default);
    fork.use(flow_1.default);
}
exports.default = default_1;
module.exports = exports["default"];
