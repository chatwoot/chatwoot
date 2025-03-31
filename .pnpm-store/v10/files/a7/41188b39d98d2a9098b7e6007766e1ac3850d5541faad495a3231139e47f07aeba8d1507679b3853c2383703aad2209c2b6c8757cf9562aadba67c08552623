import { lowerCase as A } from "../../../../lower-case@2.0.2/node_modules/lower-case/dist.es2015/index.js";
var R = [/([a-z0-9])([A-Z])/g, /([A-Z])([A-Z][a-z])/g], _ = /[^A-Z0-9]+/gi;
function o(a, e) {
  e === void 0 && (e = {});
  for (var r = e.splitRegexp, l = r === void 0 ? R : r, i = e.stripRegexp, f = i === void 0 ? _ : i, d = e.transform, g = d === void 0 ? A : d, p = e.delimiter, s = p === void 0 ? " " : p, t = v(v(a, l, "$1\0$2"), f, "\0"), c = 0, n = t.length; t.charAt(c) === "\0"; )
    c++;
  for (; t.charAt(n - 1) === "\0"; )
    n--;
  return t.slice(c, n).split("\0").map(g).join(s);
}
function v(a, e, r) {
  return e instanceof RegExp ? a.replace(e, r) : e.reduce(function(l, i) {
    return l.replace(i, r);
  }, a);
}
export {
  o as noCase
};
