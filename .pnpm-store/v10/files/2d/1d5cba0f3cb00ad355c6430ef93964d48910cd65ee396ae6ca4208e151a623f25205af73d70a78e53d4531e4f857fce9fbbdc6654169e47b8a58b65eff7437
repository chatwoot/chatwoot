export function bindAll(obj) {
    var proto = obj.constructor.prototype;
    for (var _i = 0, _a = Object.getOwnPropertyNames(proto); _i < _a.length; _i++) {
        var key = _a[_i];
        if (key !== 'constructor') {
            var desc = Object.getOwnPropertyDescriptor(obj.constructor.prototype, key);
            if (!!desc && typeof desc.value === 'function') {
                obj[key] = obj[key].bind(obj);
            }
        }
    }
    return obj;
}
//# sourceMappingURL=bind-all.js.map