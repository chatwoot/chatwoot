"use strict";
// Portions of this file are derived from getsentry/sentry-javascript by Software, Inc. dba Sentry
// Licensed under the MIT License
Object.defineProperty(exports, "__esModule", { value: true });
exports.isEvent = isEvent;
exports.isPlainObject = isPlainObject;
exports.isInstanceOf = isInstanceOf;
exports.isPrimitive = isPrimitive;
exports.isError = isError;
exports.isErrorEvent = isErrorEvent;
exports.isErrorWithStack = isErrorWithStack;
exports.isBuiltin = isBuiltin;
exports.isDOMException = isDOMException;
exports.isDOMError = isDOMError;
var core_1 = require("@posthog/core");
function isEvent(candidate) {
    return !(0, core_1.isUndefined)(Event) && isInstanceOf(candidate, Event);
}
function isPlainObject(candidate) {
    return isBuiltin(candidate, 'Object');
}
function isInstanceOf(candidate, base) {
    try {
        return candidate instanceof base;
    }
    catch (_a) {
        return false;
    }
}
function isPrimitive(candidate) {
    return (0, core_1.isNull)(candidate) || (!(0, core_1.isObject)(candidate) && !(0, core_1.isFunction)(candidate));
}
function isError(candidate) {
    switch (Object.prototype.toString.call(candidate)) {
        case '[object Error]':
        case '[object Exception]':
        case '[object DOMException]':
        case '[object DOMError]':
            return true;
        default:
            return isInstanceOf(candidate, Error);
    }
}
function isErrorEvent(event) {
    return isBuiltin(event, 'ErrorEvent');
}
function isErrorWithStack(candidate) {
    return 'stack' in candidate;
}
function isBuiltin(candidate, className) {
    return Object.prototype.toString.call(candidate) === "[object ".concat(className, "]");
}
function isDOMException(candidate) {
    return isBuiltin(candidate, 'DOMException');
}
function isDOMError(candidate) {
    return isBuiltin(candidate, 'DOMError');
}
//# sourceMappingURL=type-checking.js.map