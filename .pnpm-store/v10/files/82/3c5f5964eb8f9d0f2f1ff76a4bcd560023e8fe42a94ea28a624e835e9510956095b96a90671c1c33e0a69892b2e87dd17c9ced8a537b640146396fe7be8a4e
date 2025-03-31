"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.hasUser = exports.isPlainObject = exports.isFunction = exports.isNumber = exports.isString = void 0;
function isString(obj) {
    return typeof obj === 'string';
}
exports.isString = isString;
function isNumber(obj) {
    return typeof obj === 'number';
}
exports.isNumber = isNumber;
function isFunction(obj) {
    return typeof obj === 'function';
}
exports.isFunction = isFunction;
function isPlainObject(obj) {
    return (Object.prototype.toString.call(obj).slice(8, -1).toLowerCase() === 'object');
}
exports.isPlainObject = isPlainObject;
function hasUser(event) {
    var _a, _b, _c;
    var id = (_c = (_b = (_a = event.userId) !== null && _a !== void 0 ? _a : event.anonymousId) !== null && _b !== void 0 ? _b : event.groupId) !== null && _c !== void 0 ? _c : event.previousId;
    return isString(id);
}
exports.hasUser = hasUser;
//# sourceMappingURL=helpers.js.map