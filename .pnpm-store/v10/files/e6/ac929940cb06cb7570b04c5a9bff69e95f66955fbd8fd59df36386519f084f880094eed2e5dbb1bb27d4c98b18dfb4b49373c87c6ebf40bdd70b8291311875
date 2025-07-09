export var pickBy = function (obj, fn) {
    return Object.keys(obj)
        .filter(function (k) { return fn(k, obj[k]); })
        .reduce(function (acc, key) { return ((acc[key] = obj[key]), acc); }, {});
};
//# sourceMappingURL=pick.js.map