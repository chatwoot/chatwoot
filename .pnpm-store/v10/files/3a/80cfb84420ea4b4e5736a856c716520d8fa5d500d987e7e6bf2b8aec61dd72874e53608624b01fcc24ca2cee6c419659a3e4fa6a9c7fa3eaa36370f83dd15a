import { __assign as o } from "../../../../tslib@2.6.2/node_modules/tslib/tslib.es6.js";
import { noCase as t } from "../../../../no-case@3.0.4/node_modules/no-case/dist.es2015/index.js";
function f(r, a) {
  var e = r.charAt(0), s = r.substr(1).toLowerCase();
  return a > 0 && e >= "0" && e <= "9" ? "_" + e + s : "" + e.toUpperCase() + s;
}
function c(r) {
  return r.charAt(0).toUpperCase() + r.slice(1).toLowerCase();
}
function i(r, a) {
  return a === void 0 && (a = {}), t(r, o({ delimiter: "", transform: f }, a));
}
export {
  i as pascalCase,
  f as pascalCaseTransform,
  c as pascalCaseTransformMerge
};
