"use strict";
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.stripEmptyProperties = exports.safewrapClass = exports.safewrap = exports.trySafe = exports.include = exports.extendArray = exports.extend = void 0;
exports.eachArray = eachArray;
exports.each = each;
exports.entries = entries;
exports._copyAndTruncateStrings = _copyAndTruncateStrings;
exports.isCrossDomainCookie = isCrossDomainCookie;
exports.find = find;
exports.addEventListener = addEventListener;
exports.migrateConfigField = migrateConfigField;
var globals_1 = require("./globals");
var logger_1 = require("./logger");
var core_1 = require("@posthog/core");
var breaker = {};
function eachArray(obj, iterator, thisArg) {
    if ((0, core_1.isArray)(obj)) {
        if (globals_1.nativeForEach && obj.forEach === globals_1.nativeForEach) {
            obj.forEach(iterator, thisArg);
        }
        else if ('length' in obj && obj.length === +obj.length) {
            for (var i = 0, l = obj.length; i < l; i++) {
                if (i in obj && iterator.call(thisArg, obj[i], i) === breaker) {
                    return;
                }
            }
        }
    }
}
/**
 * @param {*=} obj
 * @param {function(...*)=} iterator
 * @param {Object=} thisArg
 */
function each(obj, iterator, thisArg) {
    var e_1, _a;
    if ((0, core_1.isNullish)(obj)) {
        return;
    }
    if ((0, core_1.isArray)(obj)) {
        return eachArray(obj, iterator, thisArg);
    }
    if ((0, core_1.isFormData)(obj)) {
        try {
            for (var _b = __values(obj.entries()), _c = _b.next(); !_c.done; _c = _b.next()) {
                var pair = _c.value;
                if (iterator.call(thisArg, pair[1], pair[0]) === breaker) {
                    return;
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_1) throw e_1.error; }
        }
        return;
    }
    for (var key in obj) {
        if (core_1.hasOwnProperty.call(obj, key)) {
            if (iterator.call(thisArg, obj[key], key) === breaker) {
                return;
            }
        }
    }
}
var extend = function (obj) {
    var args = [];
    for (var _i = 1; _i < arguments.length; _i++) {
        args[_i - 1] = arguments[_i];
    }
    eachArray(args, function (source) {
        for (var prop in source) {
            if (source[prop] !== void 0) {
                obj[prop] = source[prop];
            }
        }
    });
    return obj;
};
exports.extend = extend;
var extendArray = function (obj) {
    var args = [];
    for (var _i = 1; _i < arguments.length; _i++) {
        args[_i - 1] = arguments[_i];
    }
    eachArray(args, function (source) {
        eachArray(source, function (item) {
            obj.push(item);
        });
    });
    return obj;
};
exports.extendArray = extendArray;
var include = function (obj, target) {
    var found = false;
    if ((0, core_1.isNull)(obj)) {
        return found;
    }
    if (globals_1.nativeIndexOf && obj.indexOf === globals_1.nativeIndexOf) {
        return obj.indexOf(target) != -1;
    }
    each(obj, function (value) {
        if (found || (found = value === target)) {
            return breaker;
        }
        return;
    });
    return found;
};
exports.include = include;
/**
 * Object.entries() polyfill
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries
 */
function entries(obj) {
    var ownProps = Object.keys(obj);
    var i = ownProps.length;
    var resArray = new Array(i); // preallocate the Array
    while (i--) {
        resArray[i] = [ownProps[i], obj[ownProps[i]]];
    }
    return resArray;
}
var trySafe = function (fn) {
    try {
        return fn();
    }
    catch (_a) {
        return undefined;
    }
};
exports.trySafe = trySafe;
var safewrap = function (f) {
    return function () {
        var args = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            args[_i] = arguments[_i];
        }
        try {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            return f.apply(this, args);
        }
        catch (e) {
            logger_1.logger.critical('Implementation error. Please turn on debug mode and open a ticket on https://app.posthog.com/home#panel=support%3Asupport%3A.');
            logger_1.logger.critical(e);
        }
    };
};
exports.safewrap = safewrap;
// eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
var safewrapClass = function (klass, functions) {
    for (var i = 0; i < functions.length; i++) {
        klass.prototype[functions[i]] = (0, exports.safewrap)(klass.prototype[functions[i]]);
    }
};
exports.safewrapClass = safewrapClass;
var stripEmptyProperties = function (p) {
    var ret = {};
    each(p, function (v, k) {
        if (((0, core_1.isString)(v) && v.length > 0) || (0, core_1.isNumber)(v)) {
            ret[k] = v;
        }
    });
    return ret;
};
exports.stripEmptyProperties = stripEmptyProperties;
/**
 * Deep copies an object.
 * It handles cycles by replacing all references to them with `undefined`
 * Also supports customizing native values
 *
 * @param value
 * @param customizer
 * @returns {{}|undefined|*}
 */
function deepCircularCopy(value, customizer) {
    var COPY_IN_PROGRESS_SET = new Set();
    function internalDeepCircularCopy(value, key) {
        if (value !== Object(value))
            return customizer ? customizer(value, key) : value; // primitive value
        if (COPY_IN_PROGRESS_SET.has(value))
            return undefined;
        COPY_IN_PROGRESS_SET.add(value);
        var result;
        if ((0, core_1.isArray)(value)) {
            result = [];
            eachArray(value, function (it) {
                result.push(internalDeepCircularCopy(it));
            });
        }
        else {
            result = {};
            each(value, function (val, key) {
                if (!COPY_IN_PROGRESS_SET.has(val)) {
                    ;
                    result[key] = internalDeepCircularCopy(val, key);
                }
            });
        }
        return result;
    }
    return internalDeepCircularCopy(value);
}
function _copyAndTruncateStrings(object, maxStringLength) {
    return deepCircularCopy(object, function (value) {
        if ((0, core_1.isString)(value) && !(0, core_1.isNull)(maxStringLength)) {
            return value.slice(0, maxStringLength);
        }
        return value;
    });
}
// NOTE: Update PostHogConfig docs if you change this list
// We will not try to catch all bullets here, but we should make an effort to catch the most common ones
// You should be highly against adding more to this list, because ultimately customers can configure
// their `cross_subdomain_cookie` setting to anything they want.
var EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE = ['herokuapp.com', 'vercel.app', 'netlify.app'];
function isCrossDomainCookie(documentLocation) {
    var e_2, _a;
    var hostname = documentLocation === null || documentLocation === void 0 ? void 0 : documentLocation.hostname;
    if (!(0, core_1.isString)(hostname)) {
        return false;
    }
    // split and slice isn't a great way to match arbitrary domains,
    // but it's good enough for ensuring we only match herokuapp.com when it is the TLD
    // for the hostname
    var lastTwoParts = hostname.split('.').slice(-2).join('.');
    try {
        for (var EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1 = __values(EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE), EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1 = EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1.next(); !EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1.done; EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1 = EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1.next()) {
            var excluded = EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1.value;
            if (lastTwoParts === excluded) {
                return false;
            }
        }
    }
    catch (e_2_1) { e_2 = { error: e_2_1 }; }
    finally {
        try {
            if (EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1 && !EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1_1.done && (_a = EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1.return)) _a.call(EXCLUDED_FROM_CROSS_SUBDOMAIN_COOKIE_1);
        }
        finally { if (e_2) throw e_2.error; }
    }
    return true;
}
function find(value, predicate) {
    for (var i = 0; i < value.length; i++) {
        if (predicate(value[i])) {
            return value[i];
        }
    }
    return undefined;
}
// Use this instead of element.addEventListener to avoid eslint errors
// this properly implements the default options for passive event listeners
function addEventListener(element, event, callback, options) {
    var _a = options !== null && options !== void 0 ? options : {}, _b = _a.capture, capture = _b === void 0 ? false : _b, _c = _a.passive, passive = _c === void 0 ? true : _c;
    // This is the only place where we are allowed to call this function
    // because the whole idea is that we should be calling this instead of the built-in one
    // eslint-disable-next-line posthog-js/no-add-event-listener
    element === null || element === void 0 ? void 0 : element.addEventListener(event, callback, { capture: capture, passive: passive });
}
/**
 * Helper to migrate deprecated config fields to new field names with appropriate warnings
 * @param config - The config object to check
 * @param newField - The new field name to use
 * @param oldField - The deprecated field name to check for
 * @param defaultValue - The default value if neither field is set
 * @param loggerInstance - Optional logger instance for deprecation warnings
 * @returns The value to use (new field takes precedence over old field)
 */
function migrateConfigField(config, newField, oldField, defaultValue, loggerInstance) {
    var hasNewField = newField in config && !(0, core_1.isUndefined)(config[newField]);
    var hasOldField = oldField in config && !(0, core_1.isUndefined)(config[oldField]);
    if (hasNewField) {
        return config[newField];
    }
    if (hasOldField) {
        if (loggerInstance) {
            loggerInstance.warn("Config field '".concat(oldField, "' is deprecated. Please use '").concat(newField, "' instead. ") +
                "The old field will be removed in a future major version.");
        }
        return config[oldField];
    }
    return defaultValue;
}
//# sourceMappingURL=index.js.map