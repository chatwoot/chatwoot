import { __spreadArray } from "tslib";
export function groupBy(collection, grouper) {
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
        results[key] = __spreadArray(__spreadArray([], ((_a = results[key]) !== null && _a !== void 0 ? _a : []), true), [item], false);
    });
    return results;
}
//# sourceMappingURL=group-by.js.map