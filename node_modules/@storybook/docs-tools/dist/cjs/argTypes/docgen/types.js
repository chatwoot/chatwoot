"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.TypeSystem = void 0;
// eslint-disable-next-line @typescript-eslint/no-empty-interface
// export type DocgenType = DocgenPropType | DocgenFlowType | DocgenTypeScriptType;
var TypeSystem;
exports.TypeSystem = TypeSystem;

(function (TypeSystem) {
  TypeSystem["JAVASCRIPT"] = "JavaScript";
  TypeSystem["FLOW"] = "Flow";
  TypeSystem["TYPESCRIPT"] = "TypeScript";
  TypeSystem["UNKNOWN"] = "Unknown";
})(TypeSystem || (exports.TypeSystem = TypeSystem = {}));