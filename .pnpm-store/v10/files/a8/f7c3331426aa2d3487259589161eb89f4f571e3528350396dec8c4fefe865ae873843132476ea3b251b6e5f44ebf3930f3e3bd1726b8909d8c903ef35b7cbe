"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validation = exports.isPlainObject = exports.isFunction = exports.isNumber = exports.isString = void 0;
var tslib_1 = require("tslib");
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
var ValidationError = /** @class */ (function (_super) {
    tslib_1.__extends(ValidationError, _super);
    function ValidationError(field, message) {
        var _this = _super.call(this, message) || this;
        _this.field = field;
        return _this;
    }
    return ValidationError;
}(Error));
function validate(ctx) {
    var _a;
    var eventType = ctx && ctx.event && ctx.event.type;
    var event = ctx.event;
    if (event === undefined) {
        throw new ValidationError('event', 'Event is missing');
    }
    if (!isString(eventType)) {
        throw new ValidationError('event', 'Event is not a string');
    }
    if (eventType === 'track' && !isString(event.event)) {
        throw new ValidationError('event', 'Event is not a string');
    }
    var props = (_a = event.properties) !== null && _a !== void 0 ? _a : event.traits;
    if (eventType !== 'alias' && !isPlainObject(props)) {
        throw new ValidationError('properties', 'properties is not an object');
    }
    if (!hasUser(event)) {
        throw new ValidationError('userId', 'Missing userId or anonymousId');
    }
    return ctx;
}
exports.validation = {
    name: 'Event Validation',
    type: 'before',
    version: '1.0.0',
    isLoaded: function () { return true; },
    load: function () { return Promise.resolve(); },
    track: validate,
    identify: validate,
    page: validate,
    alias: validate,
    group: validate,
    screen: validate,
};
//# sourceMappingURL=index.js.map