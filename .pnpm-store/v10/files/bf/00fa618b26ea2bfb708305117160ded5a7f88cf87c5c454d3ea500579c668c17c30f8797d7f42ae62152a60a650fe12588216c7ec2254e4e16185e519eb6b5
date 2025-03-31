"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pickBy = void 0;
var pickBy = function (obj, fn) {
    return Object.keys(obj)
        .filter(function (k) { return fn(k, obj[k]); })
        .reduce(function (acc, key) { return ((acc[key] = obj[key]), acc); }, {});
};
exports.pickBy = pickBy;
//# sourceMappingURL=pick.js.map