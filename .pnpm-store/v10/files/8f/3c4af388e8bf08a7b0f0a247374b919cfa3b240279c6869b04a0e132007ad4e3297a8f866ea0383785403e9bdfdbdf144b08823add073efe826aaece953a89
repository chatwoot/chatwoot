import { isFunction, isPlainObject, isString, isNumber, } from '../../plugins/validation';
/**
 * Helper for the track method
 */
export function resolveArguments(eventName, properties, options, callback) {
    var _a;
    var args = [eventName, properties, options, callback];
    var name = isPlainObject(eventName) ? eventName.event : eventName;
    if (!name || !isString(name)) {
        throw new Error('Event missing');
    }
    var data = isPlainObject(eventName)
        ? (_a = eventName.properties) !== null && _a !== void 0 ? _a : {}
        : isPlainObject(properties)
            ? properties
            : {};
    var opts = {};
    if (!isFunction(options)) {
        opts = options !== null && options !== void 0 ? options : {};
    }
    if (isPlainObject(eventName) && !isFunction(properties)) {
        opts = properties !== null && properties !== void 0 ? properties : {};
    }
    var cb = args.find(isFunction);
    return [name, data, opts, cb];
}
/**
 * Helper for page, screen methods
 */
export function resolvePageArguments(category, name, properties, options, callback) {
    var _a, _b;
    var resolvedCategory = null;
    var resolvedName = null;
    var args = [category, name, properties, options, callback];
    var strings = args.filter(isString);
    if (strings[0] !== undefined && strings[1] !== undefined) {
        resolvedCategory = strings[0];
        resolvedName = strings[1];
    }
    if (strings.length === 1) {
        resolvedCategory = null;
        resolvedName = strings[0];
    }
    var resolvedCallback = args.find(isFunction);
    var objects = args.filter(function (obj) {
        if (resolvedName === null) {
            return isPlainObject(obj);
        }
        return isPlainObject(obj) || obj === null;
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
/**
 * Helper for group, identify methods
 */
export var resolveUserArguments = function (user) {
    return function () {
        var _a, _b, _c, _d, _e;
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        var id = null;
        id = (_c = (_a = args.find(isString)) !== null && _a !== void 0 ? _a : (_b = args.find(isNumber)) === null || _b === void 0 ? void 0 : _b.toString()) !== null && _c !== void 0 ? _c : user.id();
        var objects = args.filter(function (obj) {
            if (id === null) {
                return isPlainObject(obj);
            }
            return isPlainObject(obj) || obj === null;
        });
        var traits = ((_d = objects[0]) !== null && _d !== void 0 ? _d : {});
        var opts = ((_e = objects[1]) !== null && _e !== void 0 ? _e : {});
        var resolvedCallback = args.find(isFunction);
        return [id, traits, opts, resolvedCallback];
    };
};
/**
 * Helper for alias method
 */
export function resolveAliasArguments(to, from, options, callback) {
    if (isNumber(to))
        to = to.toString(); // Legacy behaviour - allow integers for alias calls
    if (isNumber(from))
        from = from.toString();
    var args = [to, from, options, callback];
    var _a = args.filter(isString), _b = _a[0], aliasTo = _b === void 0 ? to : _b, _c = _a[1], aliasFrom = _c === void 0 ? null : _c;
    var _d = args.filter(isPlainObject)[0], opts = _d === void 0 ? {} : _d;
    var resolvedCallback = args.find(isFunction);
    return [aliasTo, aliasFrom, opts, resolvedCallback];
}
//# sourceMappingURL=index.js.map