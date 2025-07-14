export function isString(obj) {
    return typeof obj === 'string';
}
export function isNumber(obj) {
    return typeof obj === 'number';
}
export function isFunction(obj) {
    return typeof obj === 'function';
}
export function isPlainObject(obj) {
    return (Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'object');
}
export function hasUser(event) {
    var _a, _b, _c;
    var id = (_c = (_b = (_a = event.userId) !== null && _a !== void 0 ? _a : event.anonymousId) !== null && _b !== void 0 ? _b : event.groupId) !== null && _c !== void 0 ? _c : event.previousId;
    return isString(id);
}
//# sourceMappingURL=helpers.js.map