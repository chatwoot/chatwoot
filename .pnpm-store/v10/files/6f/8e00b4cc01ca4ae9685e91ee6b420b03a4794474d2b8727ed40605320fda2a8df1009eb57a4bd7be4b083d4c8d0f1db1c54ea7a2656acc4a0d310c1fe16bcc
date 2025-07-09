"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.groupBy = void 0;
var tslib_1 = require("tslib");
function groupBy(collection, grouper) {
    var results = {};
    collection.forEach(function (item) {
        var _a;
        var key = undefined;
        if (typeof grouper === 'string') {
            var suggestedKey = item[grouper];
            key =
                typeof suggestedKey !== 'string'
                    ? JSON.stringify(suggestedKey)
                    : suggestedKey;
        }
        else if (grouper instanceof Function) {
            key = grouper(item);
        }
        if (key === undefined) {
            return;
        }
        results[key] = tslib_1.__spreadArray(tslib_1.__spreadArray([], ((_a = results[key]) !== null && _a !== void 0 ? _a : []), true), [item], false);
    });
    return results;
}
exports.groupBy = groupBy;
//# sourceMappingURL=group-by.js.map