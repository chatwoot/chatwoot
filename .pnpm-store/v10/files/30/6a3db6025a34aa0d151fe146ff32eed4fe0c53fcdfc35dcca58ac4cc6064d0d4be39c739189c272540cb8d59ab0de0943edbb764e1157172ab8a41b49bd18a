"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveAliasArguments = exports.resolveUserArguments = exports.resolvePageArguments = exports.resolveArguments = void 0;
var validation_1 = require("../../plugins/validation");
/**
 * Helper for the track method
 */
function resolveArguments(eventName, properties, options, callback) {
    var _a;
    var args = [eventName, properties, options, callback];
    var name = (0, validation_1.isPlainObject)(eventName) ? eventName.event : eventName;
    if (!name || !(0, validation_1.isString)(name)) {
        throw new Error('Event missing');
    }
    var data = (0, validation_1.isPlainObject)(eventName)
        ? (_a = eventName.properties) !== null && _a !== void 0 ? _a : {}
        : (0, validation_1.isPlainObject)(properties)
            ? properties
            : {};
    var opts = {};
    if (!(0, validation_1.isFunction)(options)) {
        opts = options !== null && options !== void 0 ? options : {};
    }
    if ((0, validation_1.isPlainObject)(eventName) && !(0, validation_1.isFunction)(properties)) {
        opts = properties !== null && properties !== void 0 ? properties : {};
    }
    var cb = args.find(validation_1.isFunction);
    return [name, data, opts, cb];
}
exports.resolveArguments = resolveArguments;
/**
 * Helper for page, screen methods
 */
function resolvePageArguments(category, name, properties, options, callback) {
    var _a, _b;
    var resolvedCategory = null;
    var resolvedName = null;
    var args = [category, name, properties, options, callback];
    var strings = args.filter(validation_1.isString);
    if (strings[0] !== undefined && strings[1] !== undefined) {
        resolvedCategory = strings[0];
        resolvedName = strings[1];
    }
    if (strings.length === 1) {
        resolvedCategory = null;
        resolvedName = strings[0];
    }
    var resolvedCallback = args.find(validation_1.isFunction);
    var objects = args.filter(function (obj) {
        if (resolvedName === null) {
            return (0, validation_1.isPlainObject)(obj);
        }
        return (0, validation_1.isPlainObject)(obj) || obj === null;
    });
    var resolvedProperties = ((_a = objects[0]) !== null && _a !== void 0 ? _a : {});
    var resolvedOptions = ((_b = objects[1]) !== null && _b !== void 0 ? _b : {});
    return [
        resolvedCategory,
        resolvedName,
        resolvedProperties,
        resolvedOptions,
        resolvedCallback,
    ];
}
exports.resolvePageArguments = resolvePageArguments;
/**
 * Helper for group, identify methods
 */
var resolveUserArguments = function (user) {
    return function () {
        var _a, _b, _c, _d, _e;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        var id = null;
        id = (_c = (_a = args.find(validation_1.isString)) !== null && _a !== void 0 ? _a : (_b = args.find(validation_1.isNumber)) === null || _b === void 0 ? void 0 : _b.toString()) !== null && _c !== void 0 ? _c : user.id();
        var objects = args.filter(function (obj) {
            if (id === null) {
                return (0, validation_1.isPlainObject)(obj);
            }
            return (0, validation_1.isPlainObject)(obj) || obj === null;
        });
        var traits = ((_d = objects[0]) !== null && _d !== void 0 ? _d : {});
        var opts = ((_e = objects[1]) !== null && _e !== void 0 ? _e : {});
        var resolvedCallback = args.find(validation_1.isFunction);
        return [id, traits, opts, resolvedCallback];
    };
};
exports.resolveUserArguments = resolveUserArguments;
/**
 * Helper for alias method
 */
function resolveAliasArguments(to, from, options, callback) {
    if ((0, validation_1.isNumber)(to))
        to = to.toString(); // Legacy behaviour - allow integers for alias calls
    if ((0, validation_1.isNumber)(from))
        from = from.toString();
    var args = [to, from, options, callback];
    var _a = args.filter(validation_1.isString), _b = _a[0], aliasTo = _b === void 0 ? to : _b, _c = _a[1], aliasFrom = _c === void 0 ? null : _c;
    var _d = args.filter(validation_1.isPlainObject)[0], opts = _d === void 0 ? {} : _d;
    var resolvedCallback = args.find(validation_1.isFunction);
    return [aliasTo, aliasFrom, opts, resolvedCallback];
}
exports.resolveAliasArguments = resolveAliasArguments;
//# sourceMappingURL=index.js.map