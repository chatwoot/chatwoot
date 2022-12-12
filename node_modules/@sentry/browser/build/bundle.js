/*! @sentry/browser 6.19.7 (5b3a175) | https://github.com/getsentry/sentry-javascript */
var Sentry = (function (exports) {

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
    ***************************************************************************** */
    /* global Reflect, Promise */

    var extendStatics = function(d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };

    function __extends(d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    }

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    function __values(o) {
        var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
        if (m) return m.call(o);
        if (o && typeof o.length === "number") return {
            next: function () {
                if (o && i >= o.length) o = void 0;
                return { value: o && o[i++], done: !o };
            }
        };
        throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
    }

    function __read(o, n) {
        var m = typeof Symbol === "function" && o[Symbol.iterator];
        if (!m) return o;
        var i = m.call(o), r, ar = [], e;
        try {
            while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
        }
        catch (error) { e = { error: error }; }
        finally {
            try {
                if (r && !r.done && (m = i["return"])) m.call(i);
            }
            finally { if (e) throw e.error; }
        }
        return ar;
    }

    /** @deprecated */
    function __spread() {
        for (var ar = [], i = 0; i < arguments.length; i++)
            ar = ar.concat(__read(arguments[i]));
        return ar;
    }

    /**
     * TODO(v7): Remove this enum and replace with SeverityLevel
     */
    exports.Severity = void 0;
    (function (Severity) {
        /** JSDoc */
        Severity["Fatal"] = "fatal";
        /** JSDoc */
        Severity["Error"] = "error";
        /** JSDoc */
        Severity["Warning"] = "warning";
        /** JSDoc */
        Severity["Log"] = "log";
        /** JSDoc */
        Severity["Info"] = "info";
        /** JSDoc */
        Severity["Debug"] = "debug";
        /** JSDoc */
        Severity["Critical"] = "critical";
    })(exports.Severity || (exports.Severity = {}));

    /**
     * Consumes the promise and logs the error when it rejects.
     * @param promise A promise to forget.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function forget(promise) {
        void promise.then(null, function (e) {
            // TODO: Use a better logging mechanism
            // eslint-disable-next-line no-console
            console.error(e);
        });
    }

    /**
     * NOTE: In order to avoid circular dependencies, if you add a function to this module and it needs to print something,
     * you must either a) use `console.log` rather than the logger, or b) put your function elsewhere.
     */
    var fallbackGlobalObject = {};
    /**
     * Safely get global scope object
     *
     * @returns Global scope object
     */
    function getGlobalObject() {
        return (typeof window !== 'undefined' // eslint-disable-line no-restricted-globals
                ? window // eslint-disable-line no-restricted-globals
                : typeof self !== 'undefined'
                    ? self
                    : fallbackGlobalObject);
    }
    /**
     * Returns a global singleton contained in the global `__SENTRY__` object.
     *
     * If the singleton doesn't already exist in `__SENTRY__`, it will be created using the given factory
     * function and added to the `__SENTRY__` object.
     *
     * @param name name of the global singleton on __SENTRY__
     * @param creator creator Factory function to create the singleton if it doesn't already exist on `__SENTRY__`
     * @param obj (Optional) The global object on which to look for `__SENTRY__`, if not `getGlobalObject`'s return value
     * @returns the singleton
     */
    function getGlobalSingleton(name, creator, obj) {
        var global = (obj || getGlobalObject());
        var __SENTRY__ = (global.__SENTRY__ = global.__SENTRY__ || {});
        var singleton = __SENTRY__[name] || (__SENTRY__[name] = creator());
        return singleton;
    }

    /* eslint-disable @typescript-eslint/no-explicit-any */
    /* eslint-disable @typescript-eslint/explicit-module-boundary-types */
    // eslint-disable-next-line @typescript-eslint/unbound-method
    var objectToString = Object.prototype.toString;
    /**
     * Checks whether given value's type is one of a few Error or Error-like
     * {@link isError}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isError(wat) {
        switch (objectToString.call(wat)) {
            case '[object Error]':
            case '[object Exception]':
            case '[object DOMException]':
                return true;
            default:
                return isInstanceOf(wat, Error);
        }
    }
    function isBuiltin(wat, ty) {
        return objectToString.call(wat) === "[object " + ty + "]";
    }
    /**
     * Checks whether given value's type is ErrorEvent
     * {@link isErrorEvent}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isErrorEvent(wat) {
        return isBuiltin(wat, 'ErrorEvent');
    }
    /**
     * Checks whether given value's type is DOMError
     * {@link isDOMError}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isDOMError(wat) {
        return isBuiltin(wat, 'DOMError');
    }
    /**
     * Checks whether given value's type is DOMException
     * {@link isDOMException}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isDOMException(wat) {
        return isBuiltin(wat, 'DOMException');
    }
    /**
     * Checks whether given value's type is a string
     * {@link isString}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isString(wat) {
        return isBuiltin(wat, 'String');
    }
    /**
     * Checks whether given value is a primitive (undefined, null, number, boolean, string, bigint, symbol)
     * {@link isPrimitive}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isPrimitive(wat) {
        return wat === null || (typeof wat !== 'object' && typeof wat !== 'function');
    }
    /**
     * Checks whether given value's type is an object literal
     * {@link isPlainObject}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isPlainObject(wat) {
        return isBuiltin(wat, 'Object');
    }
    /**
     * Checks whether given value's type is an Event instance
     * {@link isEvent}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isEvent(wat) {
        return typeof Event !== 'undefined' && isInstanceOf(wat, Event);
    }
    /**
     * Checks whether given value's type is an Element instance
     * {@link isElement}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isElement(wat) {
        return typeof Element !== 'undefined' && isInstanceOf(wat, Element);
    }
    /**
     * Checks whether given value's type is an regexp
     * {@link isRegExp}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isRegExp(wat) {
        return isBuiltin(wat, 'RegExp');
    }
    /**
     * Checks whether given value has a then function.
     * @param wat A value to be checked.
     */
    function isThenable(wat) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        return Boolean(wat && wat.then && typeof wat.then === 'function');
    }
    /**
     * Checks whether given value's type is a SyntheticEvent
     * {@link isSyntheticEvent}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isSyntheticEvent(wat) {
        return isPlainObject(wat) && 'nativeEvent' in wat && 'preventDefault' in wat && 'stopPropagation' in wat;
    }
    /**
     * Checks whether given value is NaN
     * {@link isNaN}.
     *
     * @param wat A value to be checked.
     * @returns A boolean representing the result.
     */
    function isNaN$1(wat) {
        return typeof wat === 'number' && wat !== wat;
    }
    /**
     * Checks whether given value's type is an instance of provided constructor.
     * {@link isInstanceOf}.
     *
     * @param wat A value to be checked.
     * @param base A constructor to be used in a check.
     * @returns A boolean representing the result.
     */
    function isInstanceOf(wat, base) {
        try {
            return wat instanceof base;
        }
        catch (_e) {
            return false;
        }
    }

    /**
     * Given a child DOM element, returns a query-selector statement describing that
     * and its ancestors
     * e.g. [HTMLElement] => body > div > input#foo.btn[name=baz]
     * @returns generated DOM path
     */
    function htmlTreeAsString(elem, keyAttrs) {
        // try/catch both:
        // - accessing event.target (see getsentry/raven-js#838, #768)
        // - `htmlTreeAsString` because it's complex, and just accessing the DOM incorrectly
        // - can throw an exception in some circumstances.
        try {
            var currentElem = elem;
            var MAX_TRAVERSE_HEIGHT = 5;
            var MAX_OUTPUT_LEN = 80;
            var out = [];
            var height = 0;
            var len = 0;
            var separator = ' > ';
            var sepLength = separator.length;
            var nextStr = void 0;
            // eslint-disable-next-line no-plusplus
            while (currentElem && height++ < MAX_TRAVERSE_HEIGHT) {
                nextStr = _htmlElementAsString(currentElem, keyAttrs);
                // bail out if
                // - nextStr is the 'html' element
                // - the length of the string that would be created exceeds MAX_OUTPUT_LEN
                //   (ignore this limit if we are on the first iteration)
                if (nextStr === 'html' || (height > 1 && len + out.length * sepLength + nextStr.length >= MAX_OUTPUT_LEN)) {
                    break;
                }
                out.push(nextStr);
                len += nextStr.length;
                currentElem = currentElem.parentNode;
            }
            return out.reverse().join(separator);
        }
        catch (_oO) {
            return '<unknown>';
        }
    }
    /**
     * Returns a simple, query-selector representation of a DOM element
     * e.g. [HTMLElement] => input#foo.btn[name=baz]
     * @returns generated DOM path
     */
    function _htmlElementAsString(el, keyAttrs) {
        var elem = el;
        var out = [];
        var className;
        var classes;
        var key;
        var attr;
        var i;
        if (!elem || !elem.tagName) {
            return '';
        }
        out.push(elem.tagName.toLowerCase());
        // Pairs of attribute keys defined in `serializeAttribute` and their values on element.
        var keyAttrPairs = keyAttrs && keyAttrs.length
            ? keyAttrs.filter(function (keyAttr) { return elem.getAttribute(keyAttr); }).map(function (keyAttr) { return [keyAttr, elem.getAttribute(keyAttr)]; })
            : null;
        if (keyAttrPairs && keyAttrPairs.length) {
            keyAttrPairs.forEach(function (keyAttrPair) {
                out.push("[" + keyAttrPair[0] + "=\"" + keyAttrPair[1] + "\"]");
            });
        }
        else {
            if (elem.id) {
                out.push("#" + elem.id);
            }
            // eslint-disable-next-line prefer-const
            className = elem.className;
            if (className && isString(className)) {
                classes = className.split(/\s+/);
                for (i = 0; i < classes.length; i++) {
                    out.push("." + classes[i]);
                }
            }
        }
        var allowedAttrs = ['type', 'name', 'title', 'alt'];
        for (i = 0; i < allowedAttrs.length; i++) {
            key = allowedAttrs[i];
            attr = elem.getAttribute(key);
            if (attr) {
                out.push("[" + key + "=\"" + attr + "\"]");
            }
        }
        return out.join('');
    }
    /**
     * A safe form of location.href
     */
    function getLocationHref() {
        var global = getGlobalObject();
        try {
            return global.document.location.href;
        }
        catch (oO) {
            return '';
        }
    }

    var setPrototypeOf = Object.setPrototypeOf || ({ __proto__: [] } instanceof Array ? setProtoOf : mixinProperties);
    /**
     * setPrototypeOf polyfill using __proto__
     */
    // eslint-disable-next-line @typescript-eslint/ban-types
    function setProtoOf(obj, proto) {
        // @ts-ignore __proto__ does not exist on obj
        obj.__proto__ = proto;
        return obj;
    }
    /**
     * setPrototypeOf polyfill using mixin
     */
    // eslint-disable-next-line @typescript-eslint/ban-types
    function mixinProperties(obj, proto) {
        for (var prop in proto) {
            if (!Object.prototype.hasOwnProperty.call(obj, prop)) {
                // @ts-ignore typescript complains about indexing so we remove
                obj[prop] = proto[prop];
            }
        }
        return obj;
    }

    /** An error emitted by Sentry SDKs and related utilities. */
    var SentryError = /** @class */ (function (_super) {
        __extends(SentryError, _super);
        function SentryError(message) {
            var _newTarget = this.constructor;
            var _this = _super.call(this, message) || this;
            _this.message = message;
            _this.name = _newTarget.prototype.constructor.name;
            setPrototypeOf(_this, _newTarget.prototype);
            return _this;
        }
        return SentryError;
    }(Error));

    /*
     * This file defines flags and constants that can be modified during compile time in order to facilitate tree shaking
     * for users.
     *
     * Debug flags need to be declared in each package individually and must not be imported across package boundaries,
     * because some build tools have trouble tree-shaking imported guards.
     *
     * As a convention, we define debug flags in a `flags.ts` file in the root of a package's `src` folder.
     *
     * Debug flag files will contain "magic strings" like `true` that may get replaced with actual values during
     * our, or the user's build process. Take care when introducing new flags - they must not throw if they are not
     * replaced.
     */
    /** Flag that is true for debug builds, false otherwise. */
    var IS_DEBUG_BUILD$3 = true;

    /** Regular expression used to parse a Dsn. */
    var DSN_REGEX = /^(?:(\w+):)\/\/(?:(\w+)(?::(\w+))?@)([\w.-]+)(?::(\d+))?\/(.+)/;
    function isValidProtocol(protocol) {
        return protocol === 'http' || protocol === 'https';
    }
    /**
     * Renders the string representation of this Dsn.
     *
     * By default, this will render the public representation without the password
     * component. To get the deprecated private representation, set `withPassword`
     * to true.
     *
     * @param withPassword When set to true, the password will be included.
     */
    function dsnToString(dsn, withPassword) {
        if (withPassword === void 0) { withPassword = false; }
        var host = dsn.host, path = dsn.path, pass = dsn.pass, port = dsn.port, projectId = dsn.projectId, protocol = dsn.protocol, publicKey = dsn.publicKey;
        return (protocol + "://" + publicKey + (withPassword && pass ? ":" + pass : '') +
            ("@" + host + (port ? ":" + port : '') + "/" + (path ? path + "/" : path) + projectId));
    }
    function dsnFromString(str) {
        var match = DSN_REGEX.exec(str);
        if (!match) {
            throw new SentryError("Invalid Sentry Dsn: " + str);
        }
        var _a = __read(match.slice(1), 6), protocol = _a[0], publicKey = _a[1], _b = _a[2], pass = _b === void 0 ? '' : _b, host = _a[3], _c = _a[4], port = _c === void 0 ? '' : _c, lastPath = _a[5];
        var path = '';
        var projectId = lastPath;
        var split = projectId.split('/');
        if (split.length > 1) {
            path = split.slice(0, -1).join('/');
            projectId = split.pop();
        }
        if (projectId) {
            var projectMatch = projectId.match(/^\d+/);
            if (projectMatch) {
                projectId = projectMatch[0];
            }
        }
        return dsnFromComponents({ host: host, pass: pass, path: path, projectId: projectId, port: port, protocol: protocol, publicKey: publicKey });
    }
    function dsnFromComponents(components) {
        // TODO this is for backwards compatibility, and can be removed in a future version
        if ('user' in components && !('publicKey' in components)) {
            components.publicKey = components.user;
        }
        return {
            user: components.publicKey || '',
            protocol: components.protocol,
            publicKey: components.publicKey || '',
            pass: components.pass || '',
            host: components.host,
            port: components.port || '',
            path: components.path || '',
            projectId: components.projectId,
        };
    }
    function validateDsn(dsn) {
        var port = dsn.port, projectId = dsn.projectId, protocol = dsn.protocol;
        var requiredComponents = ['protocol', 'publicKey', 'host', 'projectId'];
        requiredComponents.forEach(function (component) {
            if (!dsn[component]) {
                throw new SentryError("Invalid Sentry Dsn: " + component + " missing");
            }
        });
        if (!projectId.match(/^\d+$/)) {
            throw new SentryError("Invalid Sentry Dsn: Invalid projectId " + projectId);
        }
        if (!isValidProtocol(protocol)) {
            throw new SentryError("Invalid Sentry Dsn: Invalid protocol " + protocol);
        }
        if (port && isNaN(parseInt(port, 10))) {
            throw new SentryError("Invalid Sentry Dsn: Invalid port " + port);
        }
        return true;
    }
    /** The Sentry Dsn, identifying a Sentry instance and project. */
    function makeDsn(from) {
        var components = typeof from === 'string' ? dsnFromString(from) : dsnFromComponents(from);
        validateDsn(components);
        return components;
    }

    var SeverityLevels = ['fatal', 'error', 'warning', 'log', 'info', 'debug', 'critical'];

    // TODO: Implement different loggers for different environments
    var global$6 = getGlobalObject();
    /** Prefix for logging strings */
    var PREFIX = 'Sentry Logger ';
    var CONSOLE_LEVELS = ['debug', 'info', 'warn', 'error', 'log', 'assert'];
    /**
     * Temporarily disable sentry console instrumentations.
     *
     * @param callback The function to run against the original `console` messages
     * @returns The results of the callback
     */
    function consoleSandbox(callback) {
        var global = getGlobalObject();
        if (!('console' in global)) {
            return callback();
        }
        var originalConsole = global.console;
        var wrappedLevels = {};
        // Restore all wrapped console methods
        CONSOLE_LEVELS.forEach(function (level) {
            // TODO(v7): Remove this check as it's only needed for Node 6
            var originalWrappedFunc = originalConsole[level] && originalConsole[level].__sentry_original__;
            if (level in global.console && originalWrappedFunc) {
                wrappedLevels[level] = originalConsole[level];
                originalConsole[level] = originalWrappedFunc;
            }
        });
        try {
            return callback();
        }
        finally {
            // Revert restoration to wrapped state
            Object.keys(wrappedLevels).forEach(function (level) {
                originalConsole[level] = wrappedLevels[level];
            });
        }
    }
    function makeLogger() {
        var enabled = false;
        var logger = {
            enable: function () {
                enabled = true;
            },
            disable: function () {
                enabled = false;
            },
        };
        if (IS_DEBUG_BUILD$3) {
            CONSOLE_LEVELS.forEach(function (name) {
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                logger[name] = function () {
                    var args = [];
                    for (var _i = 0; _i < arguments.length; _i++) {
                        args[_i] = arguments[_i];
                    }
                    if (enabled) {
                        consoleSandbox(function () {
                            var _a;
                            (_a = global$6.console)[name].apply(_a, __spread([PREFIX + "[" + name + "]:"], args));
                        });
                    }
                };
            });
        }
        else {
            CONSOLE_LEVELS.forEach(function (name) {
                logger[name] = function () { return undefined; };
            });
        }
        return logger;
    }
    // Ensure we only have a single logger instance, even if multiple versions of @sentry/utils are being used
    var logger;
    if (IS_DEBUG_BUILD$3) {
        logger = getGlobalSingleton('logger', makeLogger);
    }
    else {
        logger = makeLogger();
    }

    /**
     * Truncates given string to the maximum characters count
     *
     * @param str An object that contains serializable values
     * @param max Maximum number of characters in truncated string (0 = unlimited)
     * @returns string Encoded
     */
    function truncate(str, max) {
        if (max === void 0) { max = 0; }
        if (typeof str !== 'string' || max === 0) {
            return str;
        }
        return str.length <= max ? str : str.substr(0, max) + "...";
    }
    /**
     * Join values in array
     * @param input array of values to be joined together
     * @param delimiter string to be placed in-between values
     * @returns Joined values
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function safeJoin(input, delimiter) {
        if (!Array.isArray(input)) {
            return '';
        }
        var output = [];
        // eslint-disable-next-line @typescript-eslint/prefer-for-of
        for (var i = 0; i < input.length; i++) {
            var value = input[i];
            try {
                output.push(String(value));
            }
            catch (e) {
                output.push('[value cannot be serialized]');
            }
        }
        return output.join(delimiter);
    }
    /**
     * Checks if the value matches a regex or includes the string
     * @param value The string value to be checked against
     * @param pattern Either a regex or a string that must be contained in value
     */
    function isMatchingPattern(value, pattern) {
        if (!isString(value)) {
            return false;
        }
        if (isRegExp(pattern)) {
            return pattern.test(value);
        }
        if (typeof pattern === 'string') {
            return value.indexOf(pattern) !== -1;
        }
        return false;
    }

    /**
     * Replace a method in an object with a wrapped version of itself.
     *
     * @param source An object that contains a method to be wrapped.
     * @param name The name of the method to be wrapped.
     * @param replacementFactory A higher-order function that takes the original version of the given method and returns a
     * wrapped version. Note: The function returned by `replacementFactory` needs to be a non-arrow function, in order to
     * preserve the correct value of `this`, and the original method must be called using `origMethod.call(this, <other
     * args>)` or `origMethod.apply(this, [<other args>])` (rather than being called directly), again to preserve `this`.
     * @returns void
     */
    function fill(source, name, replacementFactory) {
        if (!(name in source)) {
            return;
        }
        var original = source[name];
        var wrapped = replacementFactory(original);
        // Make sure it's a function first, as we need to attach an empty prototype for `defineProperties` to work
        // otherwise it'll throw "TypeError: Object.defineProperties called on non-object"
        if (typeof wrapped === 'function') {
            try {
                markFunctionWrapped(wrapped, original);
            }
            catch (_Oo) {
                // This can throw if multiple fill happens on a global object like XMLHttpRequest
                // Fixes https://github.com/getsentry/sentry-javascript/issues/2043
            }
        }
        source[name] = wrapped;
    }
    /**
     * Defines a non-enumerable property on the given object.
     *
     * @param obj The object on which to set the property
     * @param name The name of the property to be set
     * @param value The value to which to set the property
     */
    function addNonEnumerableProperty(obj, name, value) {
        Object.defineProperty(obj, name, {
            // enumerable: false, // the default, so we can save on bundle size by not explicitly setting it
            value: value,
            writable: true,
            configurable: true,
        });
    }
    /**
     * Remembers the original function on the wrapped function and
     * patches up the prototype.
     *
     * @param wrapped the wrapper function
     * @param original the original function that gets wrapped
     */
    function markFunctionWrapped(wrapped, original) {
        var proto = original.prototype || {};
        wrapped.prototype = original.prototype = proto;
        addNonEnumerableProperty(wrapped, '__sentry_original__', original);
    }
    /**
     * This extracts the original function if available.  See
     * `markFunctionWrapped` for more information.
     *
     * @param func the function to unwrap
     * @returns the unwrapped version of the function if available.
     */
    function getOriginalFunction(func) {
        return func.__sentry_original__;
    }
    /**
     * Encodes given object into url-friendly format
     *
     * @param object An object that contains serializable values
     * @returns string Encoded
     */
    function urlEncode(object) {
        return Object.keys(object)
            .map(function (key) { return encodeURIComponent(key) + "=" + encodeURIComponent(object[key]); })
            .join('&');
    }
    /**
     * Transforms any object into an object literal with all its attributes
     * attached to it.
     *
     * @param value Initial source that we have to transform in order for it to be usable by the serializer
     */
    function convertToPlainObject(value) {
        var newObj = value;
        if (isError(value)) {
            newObj = __assign({ message: value.message, name: value.name, stack: value.stack }, getOwnProperties(value));
        }
        else if (isEvent(value)) {
            var event_1 = value;
            newObj = __assign({ type: event_1.type, target: serializeEventTarget(event_1.target), currentTarget: serializeEventTarget(event_1.currentTarget) }, getOwnProperties(event_1));
            if (typeof CustomEvent !== 'undefined' && isInstanceOf(value, CustomEvent)) {
                newObj.detail = event_1.detail;
            }
        }
        return newObj;
    }
    /** Creates a string representation of the target of an `Event` object */
    function serializeEventTarget(target) {
        try {
            return isElement(target) ? htmlTreeAsString(target) : Object.prototype.toString.call(target);
        }
        catch (_oO) {
            return '<unknown>';
        }
    }
    /** Filters out all but an object's own properties */
    function getOwnProperties(obj) {
        var extractedProps = {};
        for (var property in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, property)) {
                extractedProps[property] = obj[property];
            }
        }
        return extractedProps;
    }
    /**
     * Given any captured exception, extract its keys and create a sorted
     * and truncated list that will be used inside the event message.
     * eg. `Non-error exception captured with keys: foo, bar, baz`
     */
    // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
    function extractExceptionKeysForMessage(exception, maxLength) {
        if (maxLength === void 0) { maxLength = 40; }
        var keys = Object.keys(convertToPlainObject(exception));
        keys.sort();
        if (!keys.length) {
            return '[object has no keys]';
        }
        if (keys[0].length >= maxLength) {
            return truncate(keys[0], maxLength);
        }
        for (var includedKeys = keys.length; includedKeys > 0; includedKeys--) {
            var serialized = keys.slice(0, includedKeys).join(', ');
            if (serialized.length > maxLength) {
                continue;
            }
            if (includedKeys === keys.length) {
                return serialized;
            }
            return truncate(serialized, maxLength);
        }
        return '';
    }
    /**
     * Given any object, return the new object with removed keys that value was `undefined`.
     * Works recursively on objects and arrays.
     */
    function dropUndefinedKeys(val) {
        var e_1, _a;
        if (isPlainObject(val)) {
            var rv = {};
            try {
                for (var _b = __values(Object.keys(val)), _c = _b.next(); !_c.done; _c = _b.next()) {
                    var key = _c.value;
                    if (typeof val[key] !== 'undefined') {
                        rv[key] = dropUndefinedKeys(val[key]);
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
            return rv;
        }
        if (Array.isArray(val)) {
            return val.map(dropUndefinedKeys);
        }
        return val;
    }

    var STACKTRACE_LIMIT = 50;
    /**
     * Creates a stack parser with the supplied line parsers
     *
     * StackFrames are returned in the correct order for Sentry Exception
     * frames and with Sentry SDK internal frames removed from the top and bottom
     *
     */
    function createStackParser() {
        var parsers = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            parsers[_i] = arguments[_i];
        }
        var sortedParsers = parsers.sort(function (a, b) { return a[0] - b[0]; }).map(function (p) { return p[1]; });
        return function (stack, skipFirst) {
            var e_1, _a, e_2, _b;
            if (skipFirst === void 0) { skipFirst = 0; }
            var frames = [];
            try {
                for (var _c = __values(stack.split('\n').slice(skipFirst)), _d = _c.next(); !_d.done; _d = _c.next()) {
                    var line = _d.value;
                    try {
                        for (var sortedParsers_1 = (e_2 = void 0, __values(sortedParsers)), sortedParsers_1_1 = sortedParsers_1.next(); !sortedParsers_1_1.done; sortedParsers_1_1 = sortedParsers_1.next()) {
                            var parser = sortedParsers_1_1.value;
                            var frame = parser(line);
                            if (frame) {
                                frames.push(frame);
                                break;
                            }
                        }
                    }
                    catch (e_2_1) { e_2 = { error: e_2_1 }; }
                    finally {
                        try {
                            if (sortedParsers_1_1 && !sortedParsers_1_1.done && (_b = sortedParsers_1.return)) _b.call(sortedParsers_1);
                        }
                        finally { if (e_2) throw e_2.error; }
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
                }
                finally { if (e_1) throw e_1.error; }
            }
            return stripSentryFramesAndReverse(frames);
        };
    }
    /**
     * @hidden
     */
    function stripSentryFramesAndReverse(stack) {
        if (!stack.length) {
            return [];
        }
        var localStack = stack;
        var firstFrameFunction = localStack[0].function || '';
        var lastFrameFunction = localStack[localStack.length - 1].function || '';
        // If stack starts with one of our API calls, remove it (starts, meaning it's the top of the stack - aka last call)
        if (firstFrameFunction.indexOf('captureMessage') !== -1 || firstFrameFunction.indexOf('captureException') !== -1) {
            localStack = localStack.slice(1);
        }
        // If stack ends with one of our internal API calls, remove it (ends, meaning it's the bottom of the stack - aka top-most call)
        if (lastFrameFunction.indexOf('sentryWrapped') !== -1) {
            localStack = localStack.slice(0, -1);
        }
        // The frame where the crash happened, should be the last entry in the array
        return localStack
            .slice(0, STACKTRACE_LIMIT)
            .map(function (frame) { return (__assign(__assign({}, frame), { filename: frame.filename || localStack[0].filename, function: frame.function || '?' })); })
            .reverse();
    }
    var defaultFunctionName = '<anonymous>';
    /**
     * Safely extract function name from itself
     */
    function getFunctionName(fn) {
        try {
            if (!fn || typeof fn !== 'function') {
                return defaultFunctionName;
            }
            return fn.name || defaultFunctionName;
        }
        catch (e) {
            // Just accessing custom props in some Selenium environments
            // can cause a "Permission denied" exception (see raven-js#495).
            return defaultFunctionName;
        }
    }

    /**
     * Tells whether current environment supports Fetch API
     * {@link supportsFetch}.
     *
     * @returns Answer to the given question.
     */
    function supportsFetch() {
        if (!('fetch' in getGlobalObject())) {
            return false;
        }
        try {
            new Headers();
            new Request('');
            new Response();
            return true;
        }
        catch (e) {
            return false;
        }
    }
    /**
     * isNativeFetch checks if the given function is a native implementation of fetch()
     */
    // eslint-disable-next-line @typescript-eslint/ban-types
    function isNativeFetch(func) {
        return func && /^function fetch\(\)\s+\{\s+\[native code\]\s+\}$/.test(func.toString());
    }
    /**
     * Tells whether current environment supports Fetch API natively
     * {@link supportsNativeFetch}.
     *
     * @returns true if `window.fetch` is natively implemented, false otherwise
     */
    function supportsNativeFetch() {
        if (!supportsFetch()) {
            return false;
        }
        var global = getGlobalObject();
        // Fast path to avoid DOM I/O
        // eslint-disable-next-line @typescript-eslint/unbound-method
        if (isNativeFetch(global.fetch)) {
            return true;
        }
        // window.fetch is implemented, but is polyfilled or already wrapped (e.g: by a chrome extension)
        // so create a "pure" iframe to see if that has native fetch
        var result = false;
        var doc = global.document;
        // eslint-disable-next-line deprecation/deprecation
        if (doc && typeof doc.createElement === 'function') {
            try {
                var sandbox = doc.createElement('iframe');
                sandbox.hidden = true;
                doc.head.appendChild(sandbox);
                if (sandbox.contentWindow && sandbox.contentWindow.fetch) {
                    // eslint-disable-next-line @typescript-eslint/unbound-method
                    result = isNativeFetch(sandbox.contentWindow.fetch);
                }
                doc.head.removeChild(sandbox);
            }
            catch (err) {
                logger.warn('Could not create sandbox iframe for pure fetch check, bailing to window.fetch: ', err);
            }
        }
        return result;
    }
    /**
     * Tells whether current environment supports Referrer Policy API
     * {@link supportsReferrerPolicy}.
     *
     * @returns Answer to the given question.
     */
    function supportsReferrerPolicy() {
        // Despite all stars in the sky saying that Edge supports old draft syntax, aka 'never', 'always', 'origin' and 'default'
        // (see https://caniuse.com/#feat=referrer-policy),
        // it doesn't. And it throws an exception instead of ignoring this parameter...
        // REF: https://github.com/getsentry/raven-js/issues/1233
        if (!supportsFetch()) {
            return false;
        }
        try {
            new Request('_', {
                referrerPolicy: 'origin',
            });
            return true;
        }
        catch (e) {
            return false;
        }
    }
    /**
     * Tells whether current environment supports History API
     * {@link supportsHistory}.
     *
     * @returns Answer to the given question.
     */
    function supportsHistory() {
        // NOTE: in Chrome App environment, touching history.pushState, *even inside
        //       a try/catch block*, will cause Chrome to output an error to console.error
        // borrowed from: https://github.com/angular/angular.js/pull/13945/files
        var global = getGlobalObject();
        /* eslint-disable @typescript-eslint/no-unsafe-member-access */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var chrome = global.chrome;
        var isChromePackagedApp = chrome && chrome.app && chrome.app.runtime;
        /* eslint-enable @typescript-eslint/no-unsafe-member-access */
        var hasHistoryApi = 'history' in global && !!global.history.pushState && !!global.history.replaceState;
        return !isChromePackagedApp && hasHistoryApi;
    }

    var global$5 = getGlobalObject();
    /**
     * Instrument native APIs to call handlers that can be used to create breadcrumbs, APM spans etc.
     *  - Console API
     *  - Fetch API
     *  - XHR API
     *  - History API
     *  - DOM API (click/typing)
     *  - Error API
     *  - UnhandledRejection API
     */
    var handlers = {};
    var instrumented = {};
    /** Instruments given API */
    function instrument(type) {
        if (instrumented[type]) {
            return;
        }
        instrumented[type] = true;
        switch (type) {
            case 'console':
                instrumentConsole();
                break;
            case 'dom':
                instrumentDOM();
                break;
            case 'xhr':
                instrumentXHR();
                break;
            case 'fetch':
                instrumentFetch();
                break;
            case 'history':
                instrumentHistory();
                break;
            case 'error':
                instrumentError();
                break;
            case 'unhandledrejection':
                instrumentUnhandledRejection();
                break;
            default:
                logger.warn('unknown instrumentation type:', type);
                return;
        }
    }
    /**
     * Add handler that will be called when given type of instrumentation triggers.
     * Use at your own risk, this might break without changelog notice, only used internally.
     * @hidden
     */
    function addInstrumentationHandler(type, callback) {
        handlers[type] = handlers[type] || [];
        handlers[type].push(callback);
        instrument(type);
    }
    /** JSDoc */
    function triggerHandlers(type, data) {
        var e_1, _a;
        if (!type || !handlers[type]) {
            return;
        }
        try {
            for (var _b = __values(handlers[type] || []), _c = _b.next(); !_c.done; _c = _b.next()) {
                var handler = _c.value;
                try {
                    handler(data);
                }
                catch (e) {
                    logger.error("Error while triggering instrumentation handler.\nType: " + type + "\nName: " + getFunctionName(handler) + "\nError:", e);
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
    }
    /** JSDoc */
    function instrumentConsole() {
        if (!('console' in global$5)) {
            return;
        }
        CONSOLE_LEVELS.forEach(function (level) {
            if (!(level in global$5.console)) {
                return;
            }
            fill(global$5.console, level, function (originalConsoleMethod) {
                return function () {
                    var args = [];
                    for (var _i = 0; _i < arguments.length; _i++) {
                        args[_i] = arguments[_i];
                    }
                    triggerHandlers('console', { args: args, level: level });
                    // this fails for some browsers. :(
                    if (originalConsoleMethod) {
                        originalConsoleMethod.apply(global$5.console, args);
                    }
                };
            });
        });
    }
    /** JSDoc */
    function instrumentFetch() {
        if (!supportsNativeFetch()) {
            return;
        }
        fill(global$5, 'fetch', function (originalFetch) {
            return function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                var handlerData = {
                    args: args,
                    fetchData: {
                        method: getFetchMethod(args),
                        url: getFetchUrl(args),
                    },
                    startTimestamp: Date.now(),
                };
                triggerHandlers('fetch', __assign({}, handlerData));
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                return originalFetch.apply(global$5, args).then(function (response) {
                    triggerHandlers('fetch', __assign(__assign({}, handlerData), { endTimestamp: Date.now(), response: response }));
                    return response;
                }, function (error) {
                    triggerHandlers('fetch', __assign(__assign({}, handlerData), { endTimestamp: Date.now(), error: error }));
                    // NOTE: If you are a Sentry user, and you are seeing this stack frame,
                    //       it means the sentry.javascript SDK caught an error invoking your application code.
                    //       This is expected behavior and NOT indicative of a bug with sentry.javascript.
                    throw error;
                });
            };
        });
    }
    /* eslint-disable @typescript-eslint/no-unsafe-member-access */
    /** Extract `method` from fetch call arguments */
    function getFetchMethod(fetchArgs) {
        if (fetchArgs === void 0) { fetchArgs = []; }
        if ('Request' in global$5 && isInstanceOf(fetchArgs[0], Request) && fetchArgs[0].method) {
            return String(fetchArgs[0].method).toUpperCase();
        }
        if (fetchArgs[1] && fetchArgs[1].method) {
            return String(fetchArgs[1].method).toUpperCase();
        }
        return 'GET';
    }
    /** Extract `url` from fetch call arguments */
    function getFetchUrl(fetchArgs) {
        if (fetchArgs === void 0) { fetchArgs = []; }
        if (typeof fetchArgs[0] === 'string') {
            return fetchArgs[0];
        }
        if ('Request' in global$5 && isInstanceOf(fetchArgs[0], Request)) {
            return fetchArgs[0].url;
        }
        return String(fetchArgs[0]);
    }
    /* eslint-enable @typescript-eslint/no-unsafe-member-access */
    /** JSDoc */
    function instrumentXHR() {
        if (!('XMLHttpRequest' in global$5)) {
            return;
        }
        var xhrproto = XMLHttpRequest.prototype;
        fill(xhrproto, 'open', function (originalOpen) {
            return function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                // eslint-disable-next-line @typescript-eslint/no-this-alias
                var xhr = this;
                var url = args[1];
                var xhrInfo = (xhr.__sentry_xhr__ = {
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                    method: isString(args[0]) ? args[0].toUpperCase() : args[0],
                    url: args[1],
                });
                // if Sentry key appears in URL, don't capture it as a request
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                if (isString(url) && xhrInfo.method === 'POST' && url.match(/sentry_key/)) {
                    xhr.__sentry_own_request__ = true;
                }
                var onreadystatechangeHandler = function () {
                    if (xhr.readyState === 4) {
                        try {
                            // touching statusCode in some platforms throws
                            // an exception
                            xhrInfo.status_code = xhr.status;
                        }
                        catch (e) {
                            /* do nothing */
                        }
                        triggerHandlers('xhr', {
                            args: args,
                            endTimestamp: Date.now(),
                            startTimestamp: Date.now(),
                            xhr: xhr,
                        });
                    }
                };
                if ('onreadystatechange' in xhr && typeof xhr.onreadystatechange === 'function') {
                    fill(xhr, 'onreadystatechange', function (original) {
                        return function () {
                            var readyStateArgs = [];
                            for (var _i = 0; _i < arguments.length; _i++) {
                                readyStateArgs[_i] = arguments[_i];
                            }
                            onreadystatechangeHandler();
                            return original.apply(xhr, readyStateArgs);
                        };
                    });
                }
                else {
                    xhr.addEventListener('readystatechange', onreadystatechangeHandler);
                }
                return originalOpen.apply(xhr, args);
            };
        });
        fill(xhrproto, 'send', function (originalSend) {
            return function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                if (this.__sentry_xhr__ && args[0] !== undefined) {
                    this.__sentry_xhr__.body = args[0];
                }
                triggerHandlers('xhr', {
                    args: args,
                    startTimestamp: Date.now(),
                    xhr: this,
                });
                return originalSend.apply(this, args);
            };
        });
    }
    var lastHref;
    /** JSDoc */
    function instrumentHistory() {
        if (!supportsHistory()) {
            return;
        }
        var oldOnPopState = global$5.onpopstate;
        global$5.onpopstate = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            var to = global$5.location.href;
            // keep track of the current URL state, as we always receive only the updated state
            var from = lastHref;
            lastHref = to;
            triggerHandlers('history', {
                from: from,
                to: to,
            });
            if (oldOnPopState) {
                // Apparently this can throw in Firefox when incorrectly implemented plugin is installed.
                // https://github.com/getsentry/sentry-javascript/issues/3344
                // https://github.com/bugsnag/bugsnag-js/issues/469
                try {
                    return oldOnPopState.apply(this, args);
                }
                catch (_oO) {
                    // no-empty
                }
            }
        };
        /** @hidden */
        function historyReplacementFunction(originalHistoryFunction) {
            return function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                var url = args.length > 2 ? args[2] : undefined;
                if (url) {
                    // coerce to string (this is what pushState does)
                    var from = lastHref;
                    var to = String(url);
                    // keep track of the current URL state, as we always receive only the updated state
                    lastHref = to;
                    triggerHandlers('history', {
                        from: from,
                        to: to,
                    });
                }
                return originalHistoryFunction.apply(this, args);
            };
        }
        fill(global$5.history, 'pushState', historyReplacementFunction);
        fill(global$5.history, 'replaceState', historyReplacementFunction);
    }
    var debounceDuration = 1000;
    var debounceTimerID;
    var lastCapturedEvent;
    /**
     * Decide whether the current event should finish the debounce of previously captured one.
     * @param previous previously captured event
     * @param current event to be captured
     */
    function shouldShortcircuitPreviousDebounce(previous, current) {
        // If there was no previous event, it should always be swapped for the new one.
        if (!previous) {
            return true;
        }
        // If both events have different type, then user definitely performed two separate actions. e.g. click + keypress.
        if (previous.type !== current.type) {
            return true;
        }
        try {
            // If both events have the same type, it's still possible that actions were performed on different targets.
            // e.g. 2 clicks on different buttons.
            if (previous.target !== current.target) {
                return true;
            }
        }
        catch (e) {
            // just accessing `target` property can throw an exception in some rare circumstances
            // see: https://github.com/getsentry/sentry-javascript/issues/838
        }
        // If both events have the same type _and_ same `target` (an element which triggered an event, _not necessarily_
        // to which an event listener was attached), we treat them as the same action, as we want to capture
        // only one breadcrumb. e.g. multiple clicks on the same button, or typing inside a user input box.
        return false;
    }
    /**
     * Decide whether an event should be captured.
     * @param event event to be captured
     */
    function shouldSkipDOMEvent(event) {
        // We are only interested in filtering `keypress` events for now.
        if (event.type !== 'keypress') {
            return false;
        }
        try {
            var target = event.target;
            if (!target || !target.tagName) {
                return true;
            }
            // Only consider keypress events on actual input elements. This will disregard keypresses targeting body
            // e.g.tabbing through elements, hotkeys, etc.
            if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable) {
                return false;
            }
        }
        catch (e) {
            // just accessing `target` property can throw an exception in some rare circumstances
            // see: https://github.com/getsentry/sentry-javascript/issues/838
        }
        return true;
    }
    /**
     * Wraps addEventListener to capture UI breadcrumbs
     * @param handler function that will be triggered
     * @param globalListener indicates whether event was captured by the global event listener
     * @returns wrapped breadcrumb events handler
     * @hidden
     */
    function makeDOMEventHandler(handler, globalListener) {
        if (globalListener === void 0) { globalListener = false; }
        return function (event) {
            // It's possible this handler might trigger multiple times for the same
            // event (e.g. event propagation through node ancestors).
            // Ignore if we've already captured that event.
            if (!event || lastCapturedEvent === event) {
                return;
            }
            // We always want to skip _some_ events.
            if (shouldSkipDOMEvent(event)) {
                return;
            }
            var name = event.type === 'keypress' ? 'input' : event.type;
            // If there is no debounce timer, it means that we can safely capture the new event and store it for future comparisons.
            if (debounceTimerID === undefined) {
                handler({
                    event: event,
                    name: name,
                    global: globalListener,
                });
                lastCapturedEvent = event;
            }
            // If there is a debounce awaiting, see if the new event is different enough to treat it as a unique one.
            // If that's the case, emit the previous event and store locally the newly-captured DOM event.
            else if (shouldShortcircuitPreviousDebounce(lastCapturedEvent, event)) {
                handler({
                    event: event,
                    name: name,
                    global: globalListener,
                });
                lastCapturedEvent = event;
            }
            // Start a new debounce timer that will prevent us from capturing multiple events that should be grouped together.
            clearTimeout(debounceTimerID);
            debounceTimerID = global$5.setTimeout(function () {
                debounceTimerID = undefined;
            }, debounceDuration);
        };
    }
    /** JSDoc */
    function instrumentDOM() {
        if (!('document' in global$5)) {
            return;
        }
        // Make it so that any click or keypress that is unhandled / bubbled up all the way to the document triggers our dom
        // handlers. (Normally we have only one, which captures a breadcrumb for each click or keypress.) Do this before
        // we instrument `addEventListener` so that we don't end up attaching this handler twice.
        var triggerDOMHandler = triggerHandlers.bind(null, 'dom');
        var globalDOMEventHandler = makeDOMEventHandler(triggerDOMHandler, true);
        global$5.document.addEventListener('click', globalDOMEventHandler, false);
        global$5.document.addEventListener('keypress', globalDOMEventHandler, false);
        // After hooking into click and keypress events bubbled up to `document`, we also hook into user-handled
        // clicks & keypresses, by adding an event listener of our own to any element to which they add a listener. That
        // way, whenever one of their handlers is triggered, ours will be, too. (This is needed because their handler
        // could potentially prevent the event from bubbling up to our global listeners. This way, our handler are still
        // guaranteed to fire at least once.)
        ['EventTarget', 'Node'].forEach(function (target) {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            var proto = global$5[target] && global$5[target].prototype;
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, no-prototype-builtins
            if (!proto || !proto.hasOwnProperty || !proto.hasOwnProperty('addEventListener')) {
                return;
            }
            fill(proto, 'addEventListener', function (originalAddEventListener) {
                return function (type, listener, options) {
                    if (type === 'click' || type == 'keypress') {
                        try {
                            var el = this;
                            var handlers_1 = (el.__sentry_instrumentation_handlers__ = el.__sentry_instrumentation_handlers__ || {});
                            var handlerForType = (handlers_1[type] = handlers_1[type] || { refCount: 0 });
                            if (!handlerForType.handler) {
                                var handler = makeDOMEventHandler(triggerDOMHandler);
                                handlerForType.handler = handler;
                                originalAddEventListener.call(this, type, handler, options);
                            }
                            handlerForType.refCount += 1;
                        }
                        catch (e) {
                            // Accessing dom properties is always fragile.
                            // Also allows us to skip `addEventListenrs` calls with no proper `this` context.
                        }
                    }
                    return originalAddEventListener.call(this, type, listener, options);
                };
            });
            fill(proto, 'removeEventListener', function (originalRemoveEventListener) {
                return function (type, listener, options) {
                    if (type === 'click' || type == 'keypress') {
                        try {
                            var el = this;
                            var handlers_2 = el.__sentry_instrumentation_handlers__ || {};
                            var handlerForType = handlers_2[type];
                            if (handlerForType) {
                                handlerForType.refCount -= 1;
                                // If there are no longer any custom handlers of the current type on this element, we can remove ours, too.
                                if (handlerForType.refCount <= 0) {
                                    originalRemoveEventListener.call(this, type, handlerForType.handler, options);
                                    handlerForType.handler = undefined;
                                    delete handlers_2[type]; // eslint-disable-line @typescript-eslint/no-dynamic-delete
                                }
                                // If there are no longer any custom handlers of any type on this element, cleanup everything.
                                if (Object.keys(handlers_2).length === 0) {
                                    delete el.__sentry_instrumentation_handlers__;
                                }
                            }
                        }
                        catch (e) {
                            // Accessing dom properties is always fragile.
                            // Also allows us to skip `addEventListenrs` calls with no proper `this` context.
                        }
                    }
                    return originalRemoveEventListener.call(this, type, listener, options);
                };
            });
        });
    }
    var _oldOnErrorHandler = null;
    /** JSDoc */
    function instrumentError() {
        _oldOnErrorHandler = global$5.onerror;
        global$5.onerror = function (msg, url, line, column, error) {
            triggerHandlers('error', {
                column: column,
                error: error,
                line: line,
                msg: msg,
                url: url,
            });
            if (_oldOnErrorHandler) {
                // eslint-disable-next-line prefer-rest-params
                return _oldOnErrorHandler.apply(this, arguments);
            }
            return false;
        };
    }
    var _oldOnUnhandledRejectionHandler = null;
    /** JSDoc */
    function instrumentUnhandledRejection() {
        _oldOnUnhandledRejectionHandler = global$5.onunhandledrejection;
        global$5.onunhandledrejection = function (e) {
            triggerHandlers('unhandledrejection', e);
            if (_oldOnUnhandledRejectionHandler) {
                // eslint-disable-next-line prefer-rest-params
                return _oldOnUnhandledRejectionHandler.apply(this, arguments);
            }
            return true;
        };
    }

    /* eslint-disable @typescript-eslint/no-unsafe-member-access */
    /* eslint-disable @typescript-eslint/no-explicit-any */
    /**
     * Helper to decycle json objects
     */
    function memoBuilder() {
        var hasWeakSet = typeof WeakSet === 'function';
        var inner = hasWeakSet ? new WeakSet() : [];
        function memoize(obj) {
            if (hasWeakSet) {
                if (inner.has(obj)) {
                    return true;
                }
                inner.add(obj);
                return false;
            }
            // eslint-disable-next-line @typescript-eslint/prefer-for-of
            for (var i = 0; i < inner.length; i++) {
                var value = inner[i];
                if (value === obj) {
                    return true;
                }
            }
            inner.push(obj);
            return false;
        }
        function unmemoize(obj) {
            if (hasWeakSet) {
                inner.delete(obj);
            }
            else {
                for (var i = 0; i < inner.length; i++) {
                    if (inner[i] === obj) {
                        inner.splice(i, 1);
                        break;
                    }
                }
            }
        }
        return [memoize, unmemoize];
    }

    /**
     * UUID4 generator
     *
     * @returns string Generated UUID4.
     */
    function uuid4() {
        var global = getGlobalObject();
        var crypto = global.crypto || global.msCrypto;
        if (!(crypto === void 0) && crypto.getRandomValues) {
            // Use window.crypto API if available
            var arr = new Uint16Array(8);
            crypto.getRandomValues(arr);
            // set 4 in byte 7
            // eslint-disable-next-line no-bitwise
            arr[3] = (arr[3] & 0xfff) | 0x4000;
            // set 2 most significant bits of byte 9 to '10'
            // eslint-disable-next-line no-bitwise
            arr[4] = (arr[4] & 0x3fff) | 0x8000;
            var pad = function (num) {
                var v = num.toString(16);
                while (v.length < 4) {
                    v = "0" + v;
                }
                return v;
            };
            return (pad(arr[0]) + pad(arr[1]) + pad(arr[2]) + pad(arr[3]) + pad(arr[4]) + pad(arr[5]) + pad(arr[6]) + pad(arr[7]));
        }
        // http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript/2117523#2117523
        return 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
            // eslint-disable-next-line no-bitwise
            var r = (Math.random() * 16) | 0;
            // eslint-disable-next-line no-bitwise
            var v = c === 'x' ? r : (r & 0x3) | 0x8;
            return v.toString(16);
        });
    }
    /**
     * Parses string form of URL into an object
     * // borrowed from https://tools.ietf.org/html/rfc3986#appendix-B
     * // intentionally using regex and not <a/> href parsing trick because React Native and other
     * // environments where DOM might not be available
     * @returns parsed URL object
     */
    function parseUrl(url) {
        if (!url) {
            return {};
        }
        var match = url.match(/^(([^:/?#]+):)?(\/\/([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$/);
        if (!match) {
            return {};
        }
        // coerce to undefined values to empty string so we don't get 'undefined'
        var query = match[6] || '';
        var fragment = match[8] || '';
        return {
            host: match[4],
            path: match[5],
            protocol: match[2],
            relative: match[5] + query + fragment,
        };
    }
    function getFirstException(event) {
        return event.exception && event.exception.values ? event.exception.values[0] : undefined;
    }
    /**
     * Extracts either message or type+value from an event that can be used for user-facing logs
     * @returns event's description
     */
    function getEventDescription(event) {
        var message = event.message, eventId = event.event_id;
        if (message) {
            return message;
        }
        var firstException = getFirstException(event);
        if (firstException) {
            if (firstException.type && firstException.value) {
                return firstException.type + ": " + firstException.value;
            }
            return firstException.type || firstException.value || eventId || '<unknown>';
        }
        return eventId || '<unknown>';
    }
    /**
     * Adds exception values, type and value to an synthetic Exception.
     * @param event The event to modify.
     * @param value Value of the exception.
     * @param type Type of the exception.
     * @hidden
     */
    function addExceptionTypeValue(event, value, type) {
        var exception = (event.exception = event.exception || {});
        var values = (exception.values = exception.values || []);
        var firstException = (values[0] = values[0] || {});
        if (!firstException.value) {
            firstException.value = value || '';
        }
        if (!firstException.type) {
            firstException.type = type || 'Error';
        }
    }
    /**
     * Adds exception mechanism data to a given event. Uses defaults if the second parameter is not passed.
     *
     * @param event The event to modify.
     * @param newMechanism Mechanism data to add to the event.
     * @hidden
     */
    function addExceptionMechanism(event, newMechanism) {
        var firstException = getFirstException(event);
        if (!firstException) {
            return;
        }
        var defaultMechanism = { type: 'generic', handled: true };
        var currentMechanism = firstException.mechanism;
        firstException.mechanism = __assign(__assign(__assign({}, defaultMechanism), currentMechanism), newMechanism);
        if (newMechanism && 'data' in newMechanism) {
            var mergedData = __assign(__assign({}, (currentMechanism && currentMechanism.data)), newMechanism.data);
            firstException.mechanism.data = mergedData;
        }
    }
    /**
     * Checks whether or not we've already captured the given exception (note: not an identical exception - the very object
     * in question), and marks it captured if not.
     *
     * This is useful because it's possible for an error to get captured by more than one mechanism. After we intercept and
     * record an error, we rethrow it (assuming we've intercepted it before it's reached the top-level global handlers), so
     * that we don't interfere with whatever effects the error might have had were the SDK not there. At that point, because
     * the error has been rethrown, it's possible for it to bubble up to some other code we've instrumented. If it's not
     * caught after that, it will bubble all the way up to the global handlers (which of course we also instrument). This
     * function helps us ensure that even if we encounter the same error more than once, we only record it the first time we
     * see it.
     *
     * Note: It will ignore primitives (always return `false` and not mark them as seen), as properties can't be set on
     * them. {@link: Object.objectify} can be used on exceptions to convert any that are primitives into their equivalent
     * object wrapper forms so that this check will always work. However, because we need to flag the exact object which
     * will get rethrown, and because that rethrowing happens outside of the event processing pipeline, the objectification
     * must be done before the exception captured.
     *
     * @param A thrown exception to check or flag as having been seen
     * @returns `true` if the exception has already been captured, `false` if not (with the side effect of marking it seen)
     */
    function checkOrSetAlreadyCaught(exception) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        if (exception && exception.__sentry_captured__) {
            return true;
        }
        try {
            // set it this way rather than by assignment so that it's not ennumerable and therefore isn't recorded by the
            // `ExtraErrorData` integration
            addNonEnumerableProperty(exception, '__sentry_captured__', true);
        }
        catch (err) {
            // `exception` is a primitive, so we can't mark it seen
        }
        return false;
    }

    /**
     * Recursively normalizes the given object.
     *
     * - Creates a copy to prevent original input mutation
     * - Skips non-enumerable properties
     * - When stringifying, calls `toJSON` if implemented
     * - Removes circular references
     * - Translates non-serializable values (`undefined`/`NaN`/functions) to serializable format
     * - Translates known global objects/classes to a string representations
     * - Takes care of `Error` object serialization
     * - Optionally limits depth of final output
     * - Optionally limits number of properties/elements included in any single object/array
     *
     * @param input The object to be normalized.
     * @param depth The max depth to which to normalize the object. (Anything deeper stringified whole.)
     * @param maxProperties The max number of elements or properties to be included in any single array or
     * object in the normallized output..
     * @returns A normalized version of the object, or `"**non-serializable**"` if any errors are thrown during normalization.
     */
    function normalize(input, depth, maxProperties) {
        if (depth === void 0) { depth = +Infinity; }
        if (maxProperties === void 0) { maxProperties = +Infinity; }
        try {
            // since we're at the outermost level, there is no key
            return visit('', input, depth, maxProperties);
        }
        catch (err) {
            return { ERROR: "**non-serializable** (" + err + ")" };
        }
    }
    /** JSDoc */
    function normalizeToSize(object, 
    // Default Node.js REPL depth
    depth, 
    // 100kB, as 200kB is max payload size, so half sounds reasonable
    maxSize) {
        if (depth === void 0) { depth = 3; }
        if (maxSize === void 0) { maxSize = 100 * 1024; }
        var normalized = normalize(object, depth);
        if (jsonSize(normalized) > maxSize) {
            return normalizeToSize(object, depth - 1, maxSize);
        }
        return normalized;
    }
    /**
     * Visits a node to perform normalization on it
     *
     * @param key The key corresponding to the given node
     * @param value The node to be visited
     * @param depth Optional number indicating the maximum recursion depth
     * @param maxProperties Optional maximum number of properties/elements included in any single object/array
     * @param memo Optional Memo class handling decycling
     */
    function visit(key, value, depth, maxProperties, memo) {
        if (depth === void 0) { depth = +Infinity; }
        if (maxProperties === void 0) { maxProperties = +Infinity; }
        if (memo === void 0) { memo = memoBuilder(); }
        var _a = __read(memo, 2), memoize = _a[0], unmemoize = _a[1];
        // If the value has a `toJSON` method, see if we can bail and let it do the work
        var valueWithToJSON = value;
        if (valueWithToJSON && typeof valueWithToJSON.toJSON === 'function') {
            try {
                return valueWithToJSON.toJSON();
            }
            catch (err) {
                // pass (The built-in `toJSON` failed, but we can still try to do it ourselves)
            }
        }
        // Get the simple cases out of the way first
        if (value === null || (['number', 'boolean', 'string'].includes(typeof value) && !isNaN$1(value))) {
            return value;
        }
        var stringified = stringifyValue(key, value);
        // Anything we could potentially dig into more (objects or arrays) will have come back as `"[object XXXX]"`.
        // Everything else will have already been serialized, so if we don't see that pattern, we're done.
        if (!stringified.startsWith('[object ')) {
            return stringified;
        }
        // We're also done if we've reached the max depth
        if (depth === 0) {
            // At this point we know `serialized` is a string of the form `"[object XXXX]"`. Clean it up so it's just `"[XXXX]"`.
            return stringified.replace('object ', '');
        }
        // If we've already visited this branch, bail out, as it's circular reference. If not, note that we're seeing it now.
        if (memoize(value)) {
            return '[Circular ~]';
        }
        // At this point we know we either have an object or an array, we haven't seen it before, and we're going to recurse
        // because we haven't yet reached the max depth. Create an accumulator to hold the results of visiting each
        // property/entry, and keep track of the number of items we add to it.
        var normalized = (Array.isArray(value) ? [] : {});
        var numAdded = 0;
        // Before we begin, convert`Error` and`Event` instances into plain objects, since some of each of their relevant
        // properties are non-enumerable and otherwise would get missed.
        var visitable = (isError(value) || isEvent(value) ? convertToPlainObject(value) : value);
        for (var visitKey in visitable) {
            // Avoid iterating over fields in the prototype if they've somehow been exposed to enumeration.
            if (!Object.prototype.hasOwnProperty.call(visitable, visitKey)) {
                continue;
            }
            if (numAdded >= maxProperties) {
                normalized[visitKey] = '[MaxProperties ~]';
                break;
            }
            // Recursively visit all the child nodes
            var visitValue = visitable[visitKey];
            normalized[visitKey] = visit(visitKey, visitValue, depth - 1, maxProperties, memo);
            numAdded += 1;
        }
        // Once we've visited all the branches, remove the parent from memo storage
        unmemoize(value);
        // Return accumulated values
        return normalized;
    }
    /**
     * Stringify the given value. Handles various known special values and types.
     *
     * Not meant to be used on simple primitives which already have a string representation, as it will, for example, turn
     * the number 1231 into "[Object Number]", nor on `null`, as it will throw.
     *
     * @param value The value to stringify
     * @returns A stringified representation of the given value
     */
    function stringifyValue(key, 
    // this type is a tiny bit of a cheat, since this function does handle NaN (which is technically a number), but for
    // our internal use, it'll do
    value) {
        try {
            if (key === 'domain' && value && typeof value === 'object' && value._events) {
                return '[Domain]';
            }
            if (key === 'domainEmitter') {
                return '[DomainEmitter]';
            }
            // It's safe to use `global`, `window`, and `document` here in this manner, as we are asserting using `typeof` first
            // which won't throw if they are not present.
            if (typeof global !== 'undefined' && value === global) {
                return '[Global]';
            }
            // eslint-disable-next-line no-restricted-globals
            if (typeof window !== 'undefined' && value === window) {
                return '[Window]';
            }
            // eslint-disable-next-line no-restricted-globals
            if (typeof document !== 'undefined' && value === document) {
                return '[Document]';
            }
            // React's SyntheticEvent thingy
            if (isSyntheticEvent(value)) {
                return '[SyntheticEvent]';
            }
            if (typeof value === 'number' && value !== value) {
                return '[NaN]';
            }
            // this catches `undefined` (but not `null`, which is a primitive and can be serialized on its own)
            if (value === void 0) {
                return '[undefined]';
            }
            if (typeof value === 'function') {
                return "[Function: " + getFunctionName(value) + "]";
            }
            if (typeof value === 'symbol') {
                return "[" + String(value) + "]";
            }
            // stringified BigInts are indistinguishable from regular numbers, so we need to label them to avoid confusion
            if (typeof value === 'bigint') {
                return "[BigInt: " + String(value) + "]";
            }
            // Now that we've knocked out all the special cases and the primitives, all we have left are objects. Simply casting
            // them to strings means that instances of classes which haven't defined their `toStringTag` will just come out as
            // `"[object Object]"`. If we instead look at the constructor's name (which is the same as the name of the class),
            // we can make sure that only plain objects come out that way.
            return "[object " + Object.getPrototypeOf(value).constructor.name + "]";
        }
        catch (err) {
            return "**non-serializable** (" + err + ")";
        }
    }
    /** Calculates bytes size of input string */
    function utf8Length(value) {
        // eslint-disable-next-line no-bitwise
        return ~-encodeURI(value).split(/%..|./).length;
    }
    /** Calculates bytes size of input object */
    function jsonSize(value) {
        return utf8Length(JSON.stringify(value));
    }

    /* eslint-disable @typescript-eslint/explicit-function-return-type */
    /**
     * Creates a resolved sync promise.
     *
     * @param value the value to resolve the promise with
     * @returns the resolved sync promise
     */
    function resolvedSyncPromise(value) {
        return new SyncPromise(function (resolve) {
            resolve(value);
        });
    }
    /**
     * Creates a rejected sync promise.
     *
     * @param value the value to reject the promise with
     * @returns the rejected sync promise
     */
    function rejectedSyncPromise(reason) {
        return new SyncPromise(function (_, reject) {
            reject(reason);
        });
    }
    /**
     * Thenable class that behaves like a Promise and follows it's interface
     * but is not async internally
     */
    var SyncPromise = /** @class */ (function () {
        function SyncPromise(executor) {
            var _this = this;
            this._state = 0 /* PENDING */;
            this._handlers = [];
            /** JSDoc */
            this._resolve = function (value) {
                _this._setResult(1 /* RESOLVED */, value);
            };
            /** JSDoc */
            this._reject = function (reason) {
                _this._setResult(2 /* REJECTED */, reason);
            };
            /** JSDoc */
            this._setResult = function (state, value) {
                if (_this._state !== 0 /* PENDING */) {
                    return;
                }
                if (isThenable(value)) {
                    void value.then(_this._resolve, _this._reject);
                    return;
                }
                _this._state = state;
                _this._value = value;
                _this._executeHandlers();
            };
            /** JSDoc */
            this._executeHandlers = function () {
                if (_this._state === 0 /* PENDING */) {
                    return;
                }
                var cachedHandlers = _this._handlers.slice();
                _this._handlers = [];
                cachedHandlers.forEach(function (handler) {
                    if (handler[0]) {
                        return;
                    }
                    if (_this._state === 1 /* RESOLVED */) {
                        // eslint-disable-next-line @typescript-eslint/no-floating-promises
                        handler[1](_this._value);
                    }
                    if (_this._state === 2 /* REJECTED */) {
                        handler[2](_this._value);
                    }
                    handler[0] = true;
                });
            };
            try {
                executor(this._resolve, this._reject);
            }
            catch (e) {
                this._reject(e);
            }
        }
        /** JSDoc */
        SyncPromise.prototype.then = function (onfulfilled, onrejected) {
            var _this = this;
            return new SyncPromise(function (resolve, reject) {
                _this._handlers.push([
                    false,
                    function (result) {
                        if (!onfulfilled) {
                            // TODO: ¯\_(ツ)_/¯
                            // TODO: FIXME
                            resolve(result);
                        }
                        else {
                            try {
                                resolve(onfulfilled(result));
                            }
                            catch (e) {
                                reject(e);
                            }
                        }
                    },
                    function (reason) {
                        if (!onrejected) {
                            reject(reason);
                        }
                        else {
                            try {
                                resolve(onrejected(reason));
                            }
                            catch (e) {
                                reject(e);
                            }
                        }
                    },
                ]);
                _this._executeHandlers();
            });
        };
        /** JSDoc */
        SyncPromise.prototype.catch = function (onrejected) {
            return this.then(function (val) { return val; }, onrejected);
        };
        /** JSDoc */
        SyncPromise.prototype.finally = function (onfinally) {
            var _this = this;
            return new SyncPromise(function (resolve, reject) {
                var val;
                var isRejected;
                return _this.then(function (value) {
                    isRejected = false;
                    val = value;
                    if (onfinally) {
                        onfinally();
                    }
                }, function (reason) {
                    isRejected = true;
                    val = reason;
                    if (onfinally) {
                        onfinally();
                    }
                }).then(function () {
                    if (isRejected) {
                        reject(val);
                        return;
                    }
                    resolve(val);
                });
            });
        };
        return SyncPromise;
    }());

    /**
     * Creates an new PromiseBuffer object with the specified limit
     * @param limit max number of promises that can be stored in the buffer
     */
    function makePromiseBuffer(limit) {
        var buffer = [];
        function isReady() {
            return limit === undefined || buffer.length < limit;
        }
        /**
         * Remove a promise from the queue.
         *
         * @param task Can be any PromiseLike<T>
         * @returns Removed promise.
         */
        function remove(task) {
            return buffer.splice(buffer.indexOf(task), 1)[0];
        }
        /**
         * Add a promise (representing an in-flight action) to the queue, and set it to remove itself on fulfillment.
         *
         * @param taskProducer A function producing any PromiseLike<T>; In previous versions this used to be `task:
         *        PromiseLike<T>`, but under that model, Promises were instantly created on the call-site and their executor
         *        functions therefore ran immediately. Thus, even if the buffer was full, the action still happened. By
         *        requiring the promise to be wrapped in a function, we can defer promise creation until after the buffer
         *        limit check.
         * @returns The original promise.
         */
        function add(taskProducer) {
            if (!isReady()) {
                return rejectedSyncPromise(new SentryError('Not adding Promise due to buffer limit reached.'));
            }
            // start the task and add its promise to the queue
            var task = taskProducer();
            if (buffer.indexOf(task) === -1) {
                buffer.push(task);
            }
            void task
                .then(function () { return remove(task); })
                // Use `then(null, rejectionHandler)` rather than `catch(rejectionHandler)` so that we can use `PromiseLike`
                // rather than `Promise`. `PromiseLike` doesn't have a `.catch` method, making its polyfill smaller. (ES5 didn't
                // have promises, so TS has to polyfill when down-compiling.)
                .then(null, function () {
                return remove(task).then(null, function () {
                    // We have to add another catch here because `remove()` starts a new promise chain.
                });
            });
            return task;
        }
        /**
         * Wait for all promises in the queue to resolve or for timeout to expire, whichever comes first.
         *
         * @param timeout The time, in ms, after which to resolve to `false` if the queue is still non-empty. Passing `0` (or
         * not passing anything) will make the promise wait as long as it takes for the queue to drain before resolving to
         * `true`.
         * @returns A promise which will resolve to `true` if the queue is already empty or drains before the timeout, and
         * `false` otherwise
         */
        function drain(timeout) {
            return new SyncPromise(function (resolve, reject) {
                var counter = buffer.length;
                if (!counter) {
                    return resolve(true);
                }
                // wait for `timeout` ms and then resolve to `false` (if not cancelled first)
                var capturedSetTimeout = setTimeout(function () {
                    if (timeout && timeout > 0) {
                        resolve(false);
                    }
                }, timeout);
                // if all promises resolve in time, cancel the timer and resolve to `true`
                buffer.forEach(function (item) {
                    void resolvedSyncPromise(item).then(function () {
                        // eslint-disable-next-line no-plusplus
                        if (!--counter) {
                            clearTimeout(capturedSetTimeout);
                            resolve(true);
                        }
                    }, reject);
                });
            });
        }
        return {
            $: buffer,
            add: add,
            drain: drain,
        };
    }

    function isSupportedSeverity(level) {
        return SeverityLevels.indexOf(level) !== -1;
    }
    /**
     * Converts a string-based level into a {@link Severity}.
     *
     * @param level string representation of Severity
     * @returns Severity
     */
    function severityFromString(level) {
        if (level === 'warn')
            return exports.Severity.Warning;
        if (isSupportedSeverity(level)) {
            return level;
        }
        return exports.Severity.Log;
    }

    /**
     * Converts an HTTP status code to sentry status {@link EventStatus}.
     *
     * @param code number HTTP status code
     * @returns EventStatus
     */
    function eventStatusFromHttpCode(code) {
        if (code >= 200 && code < 300) {
            return 'success';
        }
        if (code === 429) {
            return 'rate_limit';
        }
        if (code >= 400 && code < 500) {
            return 'invalid';
        }
        if (code >= 500) {
            return 'failed';
        }
        return 'unknown';
    }

    /**
     * A TimestampSource implementation for environments that do not support the Performance Web API natively.
     *
     * Note that this TimestampSource does not use a monotonic clock. A call to `nowSeconds` may return a timestamp earlier
     * than a previously returned value. We do not try to emulate a monotonic behavior in order to facilitate debugging. It
     * is more obvious to explain "why does my span have negative duration" than "why my spans have zero duration".
     */
    var dateTimestampSource = {
        nowSeconds: function () { return Date.now() / 1000; },
    };
    /**
     * Returns a wrapper around the native Performance API browser implementation, or undefined for browsers that do not
     * support the API.
     *
     * Wrapping the native API works around differences in behavior from different browsers.
     */
    function getBrowserPerformance() {
        var performance = getGlobalObject().performance;
        if (!performance || !performance.now) {
            return undefined;
        }
        // Replace performance.timeOrigin with our own timeOrigin based on Date.now().
        //
        // This is a partial workaround for browsers reporting performance.timeOrigin such that performance.timeOrigin +
        // performance.now() gives a date arbitrarily in the past.
        //
        // Additionally, computing timeOrigin in this way fills the gap for browsers where performance.timeOrigin is
        // undefined.
        //
        // The assumption that performance.timeOrigin + performance.now() ~= Date.now() is flawed, but we depend on it to
        // interact with data coming out of performance entries.
        //
        // Note that despite recommendations against it in the spec, browsers implement the Performance API with a clock that
        // might stop when the computer is asleep (and perhaps under other circumstances). Such behavior causes
        // performance.timeOrigin + performance.now() to have an arbitrary skew over Date.now(). In laptop computers, we have
        // observed skews that can be as long as days, weeks or months.
        //
        // See https://github.com/getsentry/sentry-javascript/issues/2590.
        //
        // BUG: despite our best intentions, this workaround has its limitations. It mostly addresses timings of pageload
        // transactions, but ignores the skew built up over time that can aversely affect timestamps of navigation
        // transactions of long-lived web pages.
        var timeOrigin = Date.now() - performance.now();
        return {
            now: function () { return performance.now(); },
            timeOrigin: timeOrigin,
        };
    }
    /**
     * The Performance API implementation for the current platform, if available.
     */
    var platformPerformance = getBrowserPerformance();
    var timestampSource = platformPerformance === undefined
        ? dateTimestampSource
        : {
            nowSeconds: function () { return (platformPerformance.timeOrigin + platformPerformance.now()) / 1000; },
        };
    /**
     * Returns a timestamp in seconds since the UNIX epoch using the Date API.
     */
    var dateTimestampInSeconds = dateTimestampSource.nowSeconds.bind(dateTimestampSource);
    /**
     * Returns a timestamp in seconds since the UNIX epoch using either the Performance or Date APIs, depending on the
     * availability of the Performance API.
     *
     * See `usingPerformanceAPI` to test whether the Performance API is used.
     *
     * BUG: Note that because of how browsers implement the Performance API, the clock might stop when the computer is
     * asleep. This creates a skew between `dateTimestampInSeconds` and `timestampInSeconds`. The
     * skew can grow to arbitrary amounts like days, weeks or months.
     * See https://github.com/getsentry/sentry-javascript/issues/2590.
     */
    var timestampInSeconds = timestampSource.nowSeconds.bind(timestampSource);
    /**
     * The number of milliseconds since the UNIX epoch. This value is only usable in a browser, and only when the
     * performance API is available.
     */
    ((function () {
        // Unfortunately browsers may report an inaccurate time origin data, through either performance.timeOrigin or
        // performance.timing.navigationStart, which results in poor results in performance data. We only treat time origin
        // data as reliable if they are within a reasonable threshold of the current time.
        var performance = getGlobalObject().performance;
        if (!performance || !performance.now) {
            return undefined;
        }
        var threshold = 3600 * 1000;
        var performanceNow = performance.now();
        var dateNow = Date.now();
        // if timeOrigin isn't available set delta to threshold so it isn't used
        var timeOriginDelta = performance.timeOrigin
            ? Math.abs(performance.timeOrigin + performanceNow - dateNow)
            : threshold;
        var timeOriginIsReliable = timeOriginDelta < threshold;
        // While performance.timing.navigationStart is deprecated in favor of performance.timeOrigin, performance.timeOrigin
        // is not as widely supported. Namely, performance.timeOrigin is undefined in Safari as of writing.
        // Also as of writing, performance.timing is not available in Web Workers in mainstream browsers, so it is not always
        // a valid fallback. In the absence of an initial time provided by the browser, fallback to the current time from the
        // Date API.
        // eslint-disable-next-line deprecation/deprecation
        var navigationStart = performance.timing && performance.timing.navigationStart;
        var hasNavigationStart = typeof navigationStart === 'number';
        // if navigationStart isn't available set delta to threshold so it isn't used
        var navigationStartDelta = hasNavigationStart ? Math.abs(navigationStart + performanceNow - dateNow) : threshold;
        var navigationStartIsReliable = navigationStartDelta < threshold;
        if (timeOriginIsReliable || navigationStartIsReliable) {
            // Use the more reliable time origin
            if (timeOriginDelta <= navigationStartDelta) {
                return performance.timeOrigin;
            }
            else {
                return navigationStart;
            }
        }
        return dateNow;
    }))();

    /**
     * Creates an envelope.
     * Make sure to always explicitly provide the generic to this function
     * so that the envelope types resolve correctly.
     */
    function createEnvelope(headers, items) {
        if (items === void 0) { items = []; }
        return [headers, items];
    }
    /**
     * Get the type of the envelope. Grabs the type from the first envelope item.
     */
    function getEnvelopeType(envelope) {
        var _a = __read(envelope, 2), _b = __read(_a[1], 1), _c = __read(_b[0], 1), firstItemHeader = _c[0];
        return firstItemHeader.type;
    }
    /**
     * Serializes an envelope into a string.
     */
    function serializeEnvelope(envelope) {
        var _a = __read(envelope, 2), headers = _a[0], items = _a[1];
        var serializedHeaders = JSON.stringify(headers);
        // Have to cast items to any here since Envelope is a union type
        // Fixed in Typescript 4.2
        // TODO: Remove any[] cast when we upgrade to TS 4.2
        // https://github.com/microsoft/TypeScript/issues/36390
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return items.reduce(function (acc, item) {
            var _a = __read(item, 2), itemHeaders = _a[0], payload = _a[1];
            // We do not serialize payloads that are primitives
            var serializedPayload = isPrimitive(payload) ? String(payload) : JSON.stringify(payload);
            return acc + "\n" + JSON.stringify(itemHeaders) + "\n" + serializedPayload;
        }, serializedHeaders);
    }

    /**
     * Creates client report envelope
     * @param discarded_events An array of discard events
     * @param dsn A DSN that can be set on the header. Optional.
     */
    function createClientReportEnvelope(discarded_events, dsn, timestamp) {
        var clientReportItem = [
            { type: 'client_report' },
            {
                timestamp: timestamp || dateTimestampInSeconds(),
                discarded_events: discarded_events,
            },
        ];
        return createEnvelope(dsn ? { dsn: dsn } : {}, [clientReportItem]);
    }

    var DEFAULT_RETRY_AFTER = 60 * 1000; // 60 seconds
    /**
     * Extracts Retry-After value from the request header or returns default value
     * @param header string representation of 'Retry-After' header
     * @param now current unix timestamp
     *
     */
    function parseRetryAfterHeader(header, now) {
        if (now === void 0) { now = Date.now(); }
        var headerDelay = parseInt("" + header, 10);
        if (!isNaN(headerDelay)) {
            return headerDelay * 1000;
        }
        var headerDate = Date.parse("" + header);
        if (!isNaN(headerDate)) {
            return headerDate - now;
        }
        return DEFAULT_RETRY_AFTER;
    }
    /**
     * Gets the time that given category is disabled until for rate limiting
     */
    function disabledUntil(limits, category) {
        return limits[category] || limits.all || 0;
    }
    /**
     * Checks if a category is rate limited
     */
    function isRateLimited(limits, category, now) {
        if (now === void 0) { now = Date.now(); }
        return disabledUntil(limits, category) > now;
    }
    /**
     * Update ratelimits from incoming headers.
     * Returns true if headers contains a non-empty rate limiting header.
     */
    function updateRateLimits(limits, headers, now) {
        var e_1, _a, e_2, _b;
        if (now === void 0) { now = Date.now(); }
        var updatedRateLimits = __assign({}, limits);
        // "The name is case-insensitive."
        // https://developer.mozilla.org/en-US/docs/Web/API/Headers/get
        var rateLimitHeader = headers['x-sentry-rate-limits'];
        var retryAfterHeader = headers['retry-after'];
        if (rateLimitHeader) {
            try {
                /**
                 * rate limit headers are of the form
                 *     <header>,<header>,..
                 * where each <header> is of the form
                 *     <retry_after>: <categories>: <scope>: <reason_code>
                 * where
                 *     <retry_after> is a delay in seconds
                 *     <categories> is the event type(s) (error, transaction, etc) being rate limited and is of the form
                 *         <category>;<category>;...
                 *     <scope> is what's being limited (org, project, or key) - ignored by SDK
                 *     <reason_code> is an arbitrary string like "org_quota" - ignored by SDK
                 */
                for (var _c = __values(rateLimitHeader.trim().split(',')), _d = _c.next(); !_d.done; _d = _c.next()) {
                    var limit = _d.value;
                    var parameters = limit.split(':', 2);
                    var headerDelay = parseInt(parameters[0], 10);
                    var delay = (!isNaN(headerDelay) ? headerDelay : 60) * 1000; // 60sec default
                    if (!parameters[1]) {
                        updatedRateLimits.all = now + delay;
                    }
                    else {
                        try {
                            for (var _e = (e_2 = void 0, __values(parameters[1].split(';'))), _f = _e.next(); !_f.done; _f = _e.next()) {
                                var category = _f.value;
                                updatedRateLimits[category] = now + delay;
                            }
                        }
                        catch (e_2_1) { e_2 = { error: e_2_1 }; }
                        finally {
                            try {
                                if (_f && !_f.done && (_b = _e.return)) _b.call(_e);
                            }
                            finally { if (e_2) throw e_2.error; }
                        }
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
                }
                finally { if (e_1) throw e_1.error; }
            }
        }
        else if (retryAfterHeader) {
            updatedRateLimits.all = now + parseRetryAfterHeader(retryAfterHeader, now);
        }
        return updatedRateLimits;
    }

    /**
     * Absolute maximum number of breadcrumbs added to an event.
     * The `maxBreadcrumbs` option cannot be higher than this value.
     */
    var MAX_BREADCRUMBS = 100;
    /**
     * Holds additional event information. {@link Scope.applyToEvent} will be
     * called by the client before an event will be sent.
     */
    var Scope = /** @class */ (function () {
        function Scope() {
            /** Flag if notifying is happening. */
            this._notifyingListeners = false;
            /** Callback for client to receive scope changes. */
            this._scopeListeners = [];
            /** Callback list that will be called after {@link applyToEvent}. */
            this._eventProcessors = [];
            /** Array of breadcrumbs. */
            this._breadcrumbs = [];
            /** User */
            this._user = {};
            /** Tags */
            this._tags = {};
            /** Extra */
            this._extra = {};
            /** Contexts */
            this._contexts = {};
            /**
             * A place to stash data which is needed at some point in the SDK's event processing pipeline but which shouldn't get
             * sent to Sentry
             */
            this._sdkProcessingMetadata = {};
        }
        /**
         * Inherit values from the parent scope.
         * @param scope to clone.
         */
        Scope.clone = function (scope) {
            var newScope = new Scope();
            if (scope) {
                newScope._breadcrumbs = __spread(scope._breadcrumbs);
                newScope._tags = __assign({}, scope._tags);
                newScope._extra = __assign({}, scope._extra);
                newScope._contexts = __assign({}, scope._contexts);
                newScope._user = scope._user;
                newScope._level = scope._level;
                newScope._span = scope._span;
                newScope._session = scope._session;
                newScope._transactionName = scope._transactionName;
                newScope._fingerprint = scope._fingerprint;
                newScope._eventProcessors = __spread(scope._eventProcessors);
                newScope._requestSession = scope._requestSession;
            }
            return newScope;
        };
        /**
         * Add internal on change listener. Used for sub SDKs that need to store the scope.
         * @hidden
         */
        Scope.prototype.addScopeListener = function (callback) {
            this._scopeListeners.push(callback);
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.addEventProcessor = function (callback) {
            this._eventProcessors.push(callback);
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setUser = function (user) {
            this._user = user || {};
            if (this._session) {
                this._session.update({ user: user });
            }
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.getUser = function () {
            return this._user;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.getRequestSession = function () {
            return this._requestSession;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setRequestSession = function (requestSession) {
            this._requestSession = requestSession;
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setTags = function (tags) {
            this._tags = __assign(__assign({}, this._tags), tags);
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setTag = function (key, value) {
            var _a;
            this._tags = __assign(__assign({}, this._tags), (_a = {}, _a[key] = value, _a));
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setExtras = function (extras) {
            this._extra = __assign(__assign({}, this._extra), extras);
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setExtra = function (key, extra) {
            var _a;
            this._extra = __assign(__assign({}, this._extra), (_a = {}, _a[key] = extra, _a));
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setFingerprint = function (fingerprint) {
            this._fingerprint = fingerprint;
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setLevel = function (level) {
            this._level = level;
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setTransactionName = function (name) {
            this._transactionName = name;
            this._notifyScopeListeners();
            return this;
        };
        /**
         * Can be removed in major version.
         * @deprecated in favor of {@link this.setTransactionName}
         */
        Scope.prototype.setTransaction = function (name) {
            return this.setTransactionName(name);
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setContext = function (key, context) {
            var _a;
            if (context === null) {
                // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
                delete this._contexts[key];
            }
            else {
                this._contexts = __assign(__assign({}, this._contexts), (_a = {}, _a[key] = context, _a));
            }
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setSpan = function (span) {
            this._span = span;
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.getSpan = function () {
            return this._span;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.getTransaction = function () {
            // Often, this span (if it exists at all) will be a transaction, but it's not guaranteed to be. Regardless, it will
            // have a pointer to the currently-active transaction.
            var span = this.getSpan();
            return span && span.transaction;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.setSession = function (session) {
            if (!session) {
                delete this._session;
            }
            else {
                this._session = session;
            }
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.getSession = function () {
            return this._session;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.update = function (captureContext) {
            if (!captureContext) {
                return this;
            }
            if (typeof captureContext === 'function') {
                var updatedScope = captureContext(this);
                return updatedScope instanceof Scope ? updatedScope : this;
            }
            if (captureContext instanceof Scope) {
                this._tags = __assign(__assign({}, this._tags), captureContext._tags);
                this._extra = __assign(__assign({}, this._extra), captureContext._extra);
                this._contexts = __assign(__assign({}, this._contexts), captureContext._contexts);
                if (captureContext._user && Object.keys(captureContext._user).length) {
                    this._user = captureContext._user;
                }
                if (captureContext._level) {
                    this._level = captureContext._level;
                }
                if (captureContext._fingerprint) {
                    this._fingerprint = captureContext._fingerprint;
                }
                if (captureContext._requestSession) {
                    this._requestSession = captureContext._requestSession;
                }
            }
            else if (isPlainObject(captureContext)) {
                // eslint-disable-next-line no-param-reassign
                captureContext = captureContext;
                this._tags = __assign(__assign({}, this._tags), captureContext.tags);
                this._extra = __assign(__assign({}, this._extra), captureContext.extra);
                this._contexts = __assign(__assign({}, this._contexts), captureContext.contexts);
                if (captureContext.user) {
                    this._user = captureContext.user;
                }
                if (captureContext.level) {
                    this._level = captureContext.level;
                }
                if (captureContext.fingerprint) {
                    this._fingerprint = captureContext.fingerprint;
                }
                if (captureContext.requestSession) {
                    this._requestSession = captureContext.requestSession;
                }
            }
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.clear = function () {
            this._breadcrumbs = [];
            this._tags = {};
            this._extra = {};
            this._user = {};
            this._contexts = {};
            this._level = undefined;
            this._transactionName = undefined;
            this._fingerprint = undefined;
            this._requestSession = undefined;
            this._span = undefined;
            this._session = undefined;
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.addBreadcrumb = function (breadcrumb, maxBreadcrumbs) {
            var maxCrumbs = typeof maxBreadcrumbs === 'number' ? Math.min(maxBreadcrumbs, MAX_BREADCRUMBS) : MAX_BREADCRUMBS;
            // No data has been changed, so don't notify scope listeners
            if (maxCrumbs <= 0) {
                return this;
            }
            var mergedBreadcrumb = __assign({ timestamp: dateTimestampInSeconds() }, breadcrumb);
            this._breadcrumbs = __spread(this._breadcrumbs, [mergedBreadcrumb]).slice(-maxCrumbs);
            this._notifyScopeListeners();
            return this;
        };
        /**
         * @inheritDoc
         */
        Scope.prototype.clearBreadcrumbs = function () {
            this._breadcrumbs = [];
            this._notifyScopeListeners();
            return this;
        };
        /**
         * Applies the current context and fingerprint to the event.
         * Note that breadcrumbs will be added by the client.
         * Also if the event has already breadcrumbs on it, we do not merge them.
         * @param event Event
         * @param hint May contain additional information about the original exception.
         * @hidden
         */
        Scope.prototype.applyToEvent = function (event, hint) {
            if (this._extra && Object.keys(this._extra).length) {
                event.extra = __assign(__assign({}, this._extra), event.extra);
            }
            if (this._tags && Object.keys(this._tags).length) {
                event.tags = __assign(__assign({}, this._tags), event.tags);
            }
            if (this._user && Object.keys(this._user).length) {
                event.user = __assign(__assign({}, this._user), event.user);
            }
            if (this._contexts && Object.keys(this._contexts).length) {
                event.contexts = __assign(__assign({}, this._contexts), event.contexts);
            }
            if (this._level) {
                event.level = this._level;
            }
            if (this._transactionName) {
                event.transaction = this._transactionName;
            }
            // We want to set the trace context for normal events only if there isn't already
            // a trace context on the event. There is a product feature in place where we link
            // errors with transaction and it relies on that.
            if (this._span) {
                event.contexts = __assign({ trace: this._span.getTraceContext() }, event.contexts);
                var transactionName = this._span.transaction && this._span.transaction.name;
                if (transactionName) {
                    event.tags = __assign({ transaction: transactionName }, event.tags);
                }
            }
            this._applyFingerprint(event);
            event.breadcrumbs = __spread((event.breadcrumbs || []), this._breadcrumbs);
            event.breadcrumbs = event.breadcrumbs.length > 0 ? event.breadcrumbs : undefined;
            event.sdkProcessingMetadata = this._sdkProcessingMetadata;
            return this._notifyEventProcessors(__spread(getGlobalEventProcessors(), this._eventProcessors), event, hint);
        };
        /**
         * Add data which will be accessible during event processing but won't get sent to Sentry
         */
        Scope.prototype.setSDKProcessingMetadata = function (newData) {
            this._sdkProcessingMetadata = __assign(__assign({}, this._sdkProcessingMetadata), newData);
            return this;
        };
        /**
         * This will be called after {@link applyToEvent} is finished.
         */
        Scope.prototype._notifyEventProcessors = function (processors, event, hint, index) {
            var _this = this;
            if (index === void 0) { index = 0; }
            return new SyncPromise(function (resolve, reject) {
                var processor = processors[index];
                if (event === null || typeof processor !== 'function') {
                    resolve(event);
                }
                else {
                    var result = processor(__assign({}, event), hint);
                    if (isThenable(result)) {
                        void result
                            .then(function (final) { return _this._notifyEventProcessors(processors, final, hint, index + 1).then(resolve); })
                            .then(null, reject);
                    }
                    else {
                        void _this._notifyEventProcessors(processors, result, hint, index + 1)
                            .then(resolve)
                            .then(null, reject);
                    }
                }
            });
        };
        /**
         * This will be called on every set call.
         */
        Scope.prototype._notifyScopeListeners = function () {
            var _this = this;
            // We need this check for this._notifyingListeners to be able to work on scope during updates
            // If this check is not here we'll produce endless recursion when something is done with the scope
            // during the callback.
            if (!this._notifyingListeners) {
                this._notifyingListeners = true;
                this._scopeListeners.forEach(function (callback) {
                    callback(_this);
                });
                this._notifyingListeners = false;
            }
        };
        /**
         * Applies fingerprint from the scope to the event if there's one,
         * uses message if there's one instead or get rid of empty fingerprint
         */
        Scope.prototype._applyFingerprint = function (event) {
            // Make sure it's an array first and we actually have something in place
            event.fingerprint = event.fingerprint
                ? Array.isArray(event.fingerprint)
                    ? event.fingerprint
                    : [event.fingerprint]
                : [];
            // If we have something on the scope, then merge it with event
            if (this._fingerprint) {
                event.fingerprint = event.fingerprint.concat(this._fingerprint);
            }
            // If we have no data at all, remove empty array default
            if (event.fingerprint && !event.fingerprint.length) {
                delete event.fingerprint;
            }
        };
        return Scope;
    }());
    /**
     * Returns the global event processors.
     */
    function getGlobalEventProcessors() {
        return getGlobalSingleton('globalEventProcessors', function () { return []; });
    }
    /**
     * Add a EventProcessor to be kept globally.
     * @param callback EventProcessor to add
     */
    function addGlobalEventProcessor(callback) {
        getGlobalEventProcessors().push(callback);
    }

    /**
     * @inheritdoc
     */
    var Session = /** @class */ (function () {
        function Session(context) {
            this.errors = 0;
            this.sid = uuid4();
            this.duration = 0;
            this.status = 'ok';
            this.init = true;
            this.ignoreDuration = false;
            // Both timestamp and started are in seconds since the UNIX epoch.
            var startingTime = timestampInSeconds();
            this.timestamp = startingTime;
            this.started = startingTime;
            if (context) {
                this.update(context);
            }
        }
        /** JSDoc */
        // eslint-disable-next-line complexity
        Session.prototype.update = function (context) {
            if (context === void 0) { context = {}; }
            if (context.user) {
                if (!this.ipAddress && context.user.ip_address) {
                    this.ipAddress = context.user.ip_address;
                }
                if (!this.did && !context.did) {
                    this.did = context.user.id || context.user.email || context.user.username;
                }
            }
            this.timestamp = context.timestamp || timestampInSeconds();
            if (context.ignoreDuration) {
                this.ignoreDuration = context.ignoreDuration;
            }
            if (context.sid) {
                // Good enough uuid validation. — Kamil
                this.sid = context.sid.length === 32 ? context.sid : uuid4();
            }
            if (context.init !== undefined) {
                this.init = context.init;
            }
            if (!this.did && context.did) {
                this.did = "" + context.did;
            }
            if (typeof context.started === 'number') {
                this.started = context.started;
            }
            if (this.ignoreDuration) {
                this.duration = undefined;
            }
            else if (typeof context.duration === 'number') {
                this.duration = context.duration;
            }
            else {
                var duration = this.timestamp - this.started;
                this.duration = duration >= 0 ? duration : 0;
            }
            if (context.release) {
                this.release = context.release;
            }
            if (context.environment) {
                this.environment = context.environment;
            }
            if (!this.ipAddress && context.ipAddress) {
                this.ipAddress = context.ipAddress;
            }
            if (!this.userAgent && context.userAgent) {
                this.userAgent = context.userAgent;
            }
            if (typeof context.errors === 'number') {
                this.errors = context.errors;
            }
            if (context.status) {
                this.status = context.status;
            }
        };
        /** JSDoc */
        Session.prototype.close = function (status) {
            if (status) {
                this.update({ status: status });
            }
            else if (this.status === 'ok') {
                this.update({ status: 'exited' });
            }
            else {
                this.update();
            }
        };
        /** JSDoc */
        Session.prototype.toJSON = function () {
            return dropUndefinedKeys({
                sid: "" + this.sid,
                init: this.init,
                // Make sure that sec is converted to ms for date constructor
                started: new Date(this.started * 1000).toISOString(),
                timestamp: new Date(this.timestamp * 1000).toISOString(),
                status: this.status,
                errors: this.errors,
                did: typeof this.did === 'number' || typeof this.did === 'string' ? "" + this.did : undefined,
                duration: this.duration,
                attrs: {
                    release: this.release,
                    environment: this.environment,
                    ip_address: this.ipAddress,
                    user_agent: this.userAgent,
                },
            });
        };
        return Session;
    }());

    /*
     * This file defines flags and constants that can be modified during compile time in order to facilitate tree shaking
     * for users.
     *
     * Debug flags need to be declared in each package individually and must not be imported across package boundaries,
     * because some build tools have trouble tree-shaking imported guards.
     *
     * As a convention, we define debug flags in a `flags.ts` file in the root of a package's `src` folder.
     *
     * Debug flag files will contain "magic strings" like `true` that may get replaced with actual values during
     * our, or the user's build process. Take care when introducing new flags - they must not throw if they are not
     * replaced.
     */
    /** Flag that is true for debug builds, false otherwise. */
    var IS_DEBUG_BUILD$2 = true;

    /**
     * API compatibility version of this hub.
     *
     * WARNING: This number should only be increased when the global interface
     * changes and new methods are introduced.
     *
     * @hidden
     */
    var API_VERSION = 4;
    /**
     * Default maximum number of breadcrumbs added to an event. Can be overwritten
     * with {@link Options.maxBreadcrumbs}.
     */
    var DEFAULT_BREADCRUMBS = 100;
    /**
     * @inheritDoc
     */
    var Hub = /** @class */ (function () {
        /**
         * Creates a new instance of the hub, will push one {@link Layer} into the
         * internal stack on creation.
         *
         * @param client bound to the hub.
         * @param scope bound to the hub.
         * @param version number, higher number means higher priority.
         */
        function Hub(client, scope, _version) {
            if (scope === void 0) { scope = new Scope(); }
            if (_version === void 0) { _version = API_VERSION; }
            this._version = _version;
            /** Is a {@link Layer}[] containing the client and scope */
            this._stack = [{}];
            this.getStackTop().scope = scope;
            if (client) {
                this.bindClient(client);
            }
        }
        /**
         * @inheritDoc
         */
        Hub.prototype.isOlderThan = function (version) {
            return this._version < version;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.bindClient = function (client) {
            var top = this.getStackTop();
            top.client = client;
            if (client && client.setupIntegrations) {
                client.setupIntegrations();
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.pushScope = function () {
            // We want to clone the content of prev scope
            var scope = Scope.clone(this.getScope());
            this.getStack().push({
                client: this.getClient(),
                scope: scope,
            });
            return scope;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.popScope = function () {
            if (this.getStack().length <= 1)
                return false;
            return !!this.getStack().pop();
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.withScope = function (callback) {
            var scope = this.pushScope();
            try {
                callback(scope);
            }
            finally {
                this.popScope();
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.getClient = function () {
            return this.getStackTop().client;
        };
        /** Returns the scope of the top stack. */
        Hub.prototype.getScope = function () {
            return this.getStackTop().scope;
        };
        /** Returns the scope stack for domains or the process. */
        Hub.prototype.getStack = function () {
            return this._stack;
        };
        /** Returns the topmost scope layer in the order domain > local > process. */
        Hub.prototype.getStackTop = function () {
            return this._stack[this._stack.length - 1];
        };
        /**
         * @inheritDoc
         */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
        Hub.prototype.captureException = function (exception, hint) {
            var eventId = (this._lastEventId = hint && hint.event_id ? hint.event_id : uuid4());
            var finalHint = hint;
            // If there's no explicit hint provided, mimic the same thing that would happen
            // in the minimal itself to create a consistent behavior.
            // We don't do this in the client, as it's the lowest level API, and doing this,
            // would prevent user from having full control over direct calls.
            if (!hint) {
                var syntheticException = void 0;
                try {
                    throw new Error('Sentry syntheticException');
                }
                catch (exception) {
                    syntheticException = exception;
                }
                finalHint = {
                    originalException: exception,
                    syntheticException: syntheticException,
                };
            }
            this._invokeClient('captureException', exception, __assign(__assign({}, finalHint), { event_id: eventId }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.captureMessage = function (message, level, hint) {
            var eventId = (this._lastEventId = hint && hint.event_id ? hint.event_id : uuid4());
            var finalHint = hint;
            // If there's no explicit hint provided, mimic the same thing that would happen
            // in the minimal itself to create a consistent behavior.
            // We don't do this in the client, as it's the lowest level API, and doing this,
            // would prevent user from having full control over direct calls.
            if (!hint) {
                var syntheticException = void 0;
                try {
                    throw new Error(message);
                }
                catch (exception) {
                    syntheticException = exception;
                }
                finalHint = {
                    originalException: message,
                    syntheticException: syntheticException,
                };
            }
            this._invokeClient('captureMessage', message, level, __assign(__assign({}, finalHint), { event_id: eventId }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.captureEvent = function (event, hint) {
            var eventId = hint && hint.event_id ? hint.event_id : uuid4();
            if (event.type !== 'transaction') {
                this._lastEventId = eventId;
            }
            this._invokeClient('captureEvent', event, __assign(__assign({}, hint), { event_id: eventId }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.lastEventId = function () {
            return this._lastEventId;
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.addBreadcrumb = function (breadcrumb, hint) {
            var _a = this.getStackTop(), scope = _a.scope, client = _a.client;
            if (!scope || !client)
                return;
            // eslint-disable-next-line @typescript-eslint/unbound-method
            var _b = (client.getOptions && client.getOptions()) || {}, _c = _b.beforeBreadcrumb, beforeBreadcrumb = _c === void 0 ? null : _c, _d = _b.maxBreadcrumbs, maxBreadcrumbs = _d === void 0 ? DEFAULT_BREADCRUMBS : _d;
            if (maxBreadcrumbs <= 0)
                return;
            var timestamp = dateTimestampInSeconds();
            var mergedBreadcrumb = __assign({ timestamp: timestamp }, breadcrumb);
            var finalBreadcrumb = beforeBreadcrumb
                ? consoleSandbox(function () { return beforeBreadcrumb(mergedBreadcrumb, hint); })
                : mergedBreadcrumb;
            if (finalBreadcrumb === null)
                return;
            scope.addBreadcrumb(finalBreadcrumb, maxBreadcrumbs);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.setUser = function (user) {
            var scope = this.getScope();
            if (scope)
                scope.setUser(user);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.setTags = function (tags) {
            var scope = this.getScope();
            if (scope)
                scope.setTags(tags);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.setExtras = function (extras) {
            var scope = this.getScope();
            if (scope)
                scope.setExtras(extras);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.setTag = function (key, value) {
            var scope = this.getScope();
            if (scope)
                scope.setTag(key, value);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.setExtra = function (key, extra) {
            var scope = this.getScope();
            if (scope)
                scope.setExtra(key, extra);
        };
        /**
         * @inheritDoc
         */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        Hub.prototype.setContext = function (name, context) {
            var scope = this.getScope();
            if (scope)
                scope.setContext(name, context);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.configureScope = function (callback) {
            var _a = this.getStackTop(), scope = _a.scope, client = _a.client;
            if (scope && client) {
                callback(scope);
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.run = function (callback) {
            var oldHub = makeMain(this);
            try {
                callback(this);
            }
            finally {
                makeMain(oldHub);
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.getIntegration = function (integration) {
            var client = this.getClient();
            if (!client)
                return null;
            try {
                return client.getIntegration(integration);
            }
            catch (_oO) {
                IS_DEBUG_BUILD$2 && logger.warn("Cannot retrieve integration " + integration.id + " from the current Hub");
                return null;
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.startSpan = function (context) {
            return this._callExtensionMethod('startSpan', context);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.startTransaction = function (context, customSamplingContext) {
            return this._callExtensionMethod('startTransaction', context, customSamplingContext);
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.traceHeaders = function () {
            return this._callExtensionMethod('traceHeaders');
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.captureSession = function (endSession) {
            if (endSession === void 0) { endSession = false; }
            // both send the update and pull the session from the scope
            if (endSession) {
                return this.endSession();
            }
            // only send the update
            this._sendSessionUpdate();
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.endSession = function () {
            var layer = this.getStackTop();
            var scope = layer && layer.scope;
            var session = scope && scope.getSession();
            if (session) {
                session.close();
            }
            this._sendSessionUpdate();
            // the session is over; take it off of the scope
            if (scope) {
                scope.setSession();
            }
        };
        /**
         * @inheritDoc
         */
        Hub.prototype.startSession = function (context) {
            var _a = this.getStackTop(), scope = _a.scope, client = _a.client;
            var _b = (client && client.getOptions()) || {}, release = _b.release, environment = _b.environment;
            // Will fetch userAgent if called from browser sdk
            var global = getGlobalObject();
            var userAgent = (global.navigator || {}).userAgent;
            var session = new Session(__assign(__assign(__assign({ release: release,
                environment: environment }, (scope && { user: scope.getUser() })), (userAgent && { userAgent: userAgent })), context));
            if (scope) {
                // End existing session if there's one
                var currentSession = scope.getSession && scope.getSession();
                if (currentSession && currentSession.status === 'ok') {
                    currentSession.update({ status: 'exited' });
                }
                this.endSession();
                // Afterwards we set the new session on the scope
                scope.setSession(session);
            }
            return session;
        };
        /**
         * Sends the current Session on the scope
         */
        Hub.prototype._sendSessionUpdate = function () {
            var _a = this.getStackTop(), scope = _a.scope, client = _a.client;
            if (!scope)
                return;
            var session = scope.getSession && scope.getSession();
            if (session) {
                if (client && client.captureSession) {
                    client.captureSession(session);
                }
            }
        };
        /**
         * Internal helper function to call a method on the top client if it exists.
         *
         * @param method The method to call on the client.
         * @param args Arguments to pass to the client function.
         */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        Hub.prototype._invokeClient = function (method) {
            var _a;
            var args = [];
            for (var _i = 1; _i < arguments.length; _i++) {
                args[_i - 1] = arguments[_i];
            }
            var _b = this.getStackTop(), scope = _b.scope, client = _b.client;
            if (client && client[method]) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-explicit-any
                (_a = client)[method].apply(_a, __spread(args, [scope]));
            }
        };
        /**
         * Calls global extension method and binding current instance to the function call
         */
        // @ts-ignore Function lacks ending return statement and return type does not include 'undefined'. ts(2366)
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        Hub.prototype._callExtensionMethod = function (method) {
            var args = [];
            for (var _i = 1; _i < arguments.length; _i++) {
                args[_i - 1] = arguments[_i];
            }
            var carrier = getMainCarrier();
            var sentry = carrier.__SENTRY__;
            if (sentry && sentry.extensions && typeof sentry.extensions[method] === 'function') {
                return sentry.extensions[method].apply(this, args);
            }
            IS_DEBUG_BUILD$2 && logger.warn("Extension method " + method + " couldn't be found, doing nothing.");
        };
        return Hub;
    }());
    /**
     * Returns the global shim registry.
     *
     * FIXME: This function is problematic, because despite always returning a valid Carrier,
     * it has an optional `__SENTRY__` property, which then in turn requires us to always perform an unnecessary check
     * at the call-site. We always access the carrier through this function, so we can guarantee that `__SENTRY__` is there.
     **/
    function getMainCarrier() {
        var carrier = getGlobalObject();
        carrier.__SENTRY__ = carrier.__SENTRY__ || {
            extensions: {},
            hub: undefined,
        };
        return carrier;
    }
    /**
     * Replaces the current main hub with the passed one on the global object
     *
     * @returns The old replaced hub
     */
    function makeMain(hub) {
        var registry = getMainCarrier();
        var oldHub = getHubFromCarrier(registry);
        setHubOnCarrier(registry, hub);
        return oldHub;
    }
    /**
     * Returns the default hub instance.
     *
     * If a hub is already registered in the global carrier but this module
     * contains a more recent version, it replaces the registered version.
     * Otherwise, the currently registered hub will be returned.
     */
    function getCurrentHub() {
        // Get main carrier (global for every environment)
        var registry = getMainCarrier();
        // If there's no hub, or its an old API, assign a new one
        if (!hasHubOnCarrier(registry) || getHubFromCarrier(registry).isOlderThan(API_VERSION)) {
            setHubOnCarrier(registry, new Hub());
        }
        // Return hub that lives on a global object
        return getHubFromCarrier(registry);
    }
    /**
     * This will tell whether a carrier has a hub on it or not
     * @param carrier object
     */
    function hasHubOnCarrier(carrier) {
        return !!(carrier && carrier.__SENTRY__ && carrier.__SENTRY__.hub);
    }
    /**
     * This will create a new {@link Hub} and add to the passed object on
     * __SENTRY__.hub.
     * @param carrier object
     * @hidden
     */
    function getHubFromCarrier(carrier) {
        return getGlobalSingleton('hub', function () { return new Hub(); }, carrier);
    }
    /**
     * This will set passed {@link Hub} on the passed object's __SENTRY__.hub attribute
     * @param carrier object
     * @param hub Hub
     * @returns A boolean indicating success or failure
     */
    function setHubOnCarrier(carrier, hub) {
        if (!carrier)
            return false;
        var __SENTRY__ = (carrier.__SENTRY__ = carrier.__SENTRY__ || {});
        __SENTRY__.hub = hub;
        return true;
    }

    /**
     * This calls a function on the current hub.
     * @param method function to call on hub.
     * @param args to pass to function.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function callOnHub(method) {
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        var hub = getCurrentHub();
        if (hub && hub[method]) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            return hub[method].apply(hub, __spread(args));
        }
        throw new Error("No hub defined or " + method + " was not found on the hub, please open a bug report.");
    }
    /**
     * Captures an exception event and sends it to Sentry.
     *
     * @param exception An exception-like object.
     * @returns The generated eventId.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
    function captureException(exception, captureContext) {
        var syntheticException = new Error('Sentry syntheticException');
        return callOnHub('captureException', exception, {
            captureContext: captureContext,
            originalException: exception,
            syntheticException: syntheticException,
        });
    }
    /**
     * Captures a message event and sends it to Sentry.
     *
     * @param message The message to send to Sentry.
     * @param Severity Define the level of the message.
     * @returns The generated eventId.
     */
    function captureMessage(message, captureContext) {
        var syntheticException = new Error(message);
        // This is necessary to provide explicit scopes upgrade, without changing the original
        // arity of the `captureMessage(message, level)` method.
        var level = typeof captureContext === 'string' ? captureContext : undefined;
        var context = typeof captureContext !== 'string' ? { captureContext: captureContext } : undefined;
        return callOnHub('captureMessage', message, level, __assign({ originalException: message, syntheticException: syntheticException }, context));
    }
    /**
     * Captures a manually created event and sends it to Sentry.
     *
     * @param event The event to send to Sentry.
     * @returns The generated eventId.
     */
    function captureEvent(event) {
        return callOnHub('captureEvent', event);
    }
    /**
     * Callback to set context information onto the scope.
     * @param callback Callback function that receives Scope.
     */
    function configureScope(callback) {
        callOnHub('configureScope', callback);
    }
    /**
     * Records a new breadcrumb which will be attached to future events.
     *
     * Breadcrumbs will be added to subsequent events to provide more context on
     * user's actions prior to an error or crash.
     *
     * @param breadcrumb The breadcrumb to record.
     */
    function addBreadcrumb(breadcrumb) {
        callOnHub('addBreadcrumb', breadcrumb);
    }
    /**
     * Sets context data with the given name.
     * @param name of the context
     * @param context Any kind of data. This data will be normalized.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function setContext(name, context) {
        callOnHub('setContext', name, context);
    }
    /**
     * Set an object that will be merged sent as extra data with the event.
     * @param extras Extras object to merge into current context.
     */
    function setExtras(extras) {
        callOnHub('setExtras', extras);
    }
    /**
     * Set an object that will be merged sent as tags data with the event.
     * @param tags Tags context object to merge into current context.
     */
    function setTags(tags) {
        callOnHub('setTags', tags);
    }
    /**
     * Set key:value that will be sent as extra data with the event.
     * @param key String of extra
     * @param extra Any kind of data. This data will be normalized.
     */
    function setExtra(key, extra) {
        callOnHub('setExtra', key, extra);
    }
    /**
     * Set key:value that will be sent as tags data with the event.
     *
     * Can also be used to unset a tag, by passing `undefined`.
     *
     * @param key String key of tag
     * @param value Value of tag
     */
    function setTag(key, value) {
        callOnHub('setTag', key, value);
    }
    /**
     * Updates user context information for future events.
     *
     * @param user User context object to be set in the current context. Pass `null` to unset the user.
     */
    function setUser(user) {
        callOnHub('setUser', user);
    }
    /**
     * Creates a new scope with and executes the given operation within.
     * The scope is automatically removed once the operation
     * finishes or throws.
     *
     * This is essentially a convenience function for:
     *
     *     pushScope();
     *     callback();
     *     popScope();
     *
     * @param callback that will be enclosed into push/popScope.
     */
    function withScope(callback) {
        callOnHub('withScope', callback);
    }
    /**
     * Starts a new `Transaction` and returns it. This is the entry point to manual tracing instrumentation.
     *
     * A tree structure can be built by adding child spans to the transaction, and child spans to other spans. To start a
     * new child span within the transaction or any span, call the respective `.startChild()` method.
     *
     * Every child span must be finished before the transaction is finished, otherwise the unfinished spans are discarded.
     *
     * The transaction must be finished with a call to its `.finish()` method, at which point the transaction with all its
     * finished child spans will be sent to Sentry.
     *
     * @param context Properties of the new `Transaction`.
     * @param customSamplingContext Information given to the transaction sampling function (along with context-dependent
     * default values). See {@link Options.tracesSampler}.
     *
     * @returns The transaction which was just started
     */
    function startTransaction(context, customSamplingContext) {
        return callOnHub('startTransaction', __assign({}, context), customSamplingContext);
    }

    var SENTRY_API_VERSION = '7';
    /** Initializes API Details */
    function initAPIDetails(dsn, metadata, tunnel) {
        return {
            initDsn: dsn,
            metadata: metadata || {},
            dsn: makeDsn(dsn),
            tunnel: tunnel,
        };
    }
    /** Returns the prefix to construct Sentry ingestion API endpoints. */
    function getBaseApiEndpoint(dsn) {
        var protocol = dsn.protocol ? dsn.protocol + ":" : '';
        var port = dsn.port ? ":" + dsn.port : '';
        return protocol + "//" + dsn.host + port + (dsn.path ? "/" + dsn.path : '') + "/api/";
    }
    /** Returns the ingest API endpoint for target. */
    function _getIngestEndpoint(dsn, target) {
        return "" + getBaseApiEndpoint(dsn) + dsn.projectId + "/" + target + "/";
    }
    /** Returns a URL-encoded string with auth config suitable for a query string. */
    function _encodedAuth(dsn) {
        return urlEncode({
            // We send only the minimum set of required information. See
            // https://github.com/getsentry/sentry-javascript/issues/2572.
            sentry_key: dsn.publicKey,
            sentry_version: SENTRY_API_VERSION,
        });
    }
    /** Returns the store endpoint URL. */
    function getStoreEndpoint(dsn) {
        return _getIngestEndpoint(dsn, 'store');
    }
    /**
     * Returns the store endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    function getStoreEndpointWithUrlEncodedAuth(dsn) {
        return getStoreEndpoint(dsn) + "?" + _encodedAuth(dsn);
    }
    /** Returns the envelope endpoint URL. */
    function _getEnvelopeEndpoint(dsn) {
        return _getIngestEndpoint(dsn, 'envelope');
    }
    /**
     * Returns the envelope endpoint URL with auth in the query string.
     *
     * Sending auth as part of the query string and not as custom HTTP headers avoids CORS preflight requests.
     */
    function getEnvelopeEndpointWithUrlEncodedAuth(dsn, tunnel) {
        return tunnel ? tunnel : _getEnvelopeEndpoint(dsn) + "?" + _encodedAuth(dsn);
    }
    /** Returns the url to the report dialog endpoint. */
    function getReportDialogEndpoint(dsnLike, dialogOptions) {
        var dsn = makeDsn(dsnLike);
        var endpoint = getBaseApiEndpoint(dsn) + "embed/error-page/";
        var encodedOptions = "dsn=" + dsnToString(dsn);
        for (var key in dialogOptions) {
            if (key === 'dsn') {
                continue;
            }
            if (key === 'user') {
                if (!dialogOptions.user) {
                    continue;
                }
                if (dialogOptions.user.name) {
                    encodedOptions += "&name=" + encodeURIComponent(dialogOptions.user.name);
                }
                if (dialogOptions.user.email) {
                    encodedOptions += "&email=" + encodeURIComponent(dialogOptions.user.email);
                }
            }
            else {
                encodedOptions += "&" + encodeURIComponent(key) + "=" + encodeURIComponent(dialogOptions[key]);
            }
        }
        return endpoint + "?" + encodedOptions;
    }

    /*
     * This file defines flags and constants that can be modified during compile time in order to facilitate tree shaking
     * for users.
     *
     * Debug flags need to be declared in each package individually and must not be imported across package boundaries,
     * because some build tools have trouble tree-shaking imported guards.
     *
     * As a convention, we define debug flags in a `flags.ts` file in the root of a package's `src` folder.
     *
     * Debug flag files will contain "magic strings" like `true` that may get replaced with actual values during
     * our, or the user's build process. Take care when introducing new flags - they must not throw if they are not
     * replaced.
     */
    /** Flag that is true for debug builds, false otherwise. */
    var IS_DEBUG_BUILD$1 = true;

    var installedIntegrations = [];
    /**
     * @private
     */
    function filterDuplicates(integrations) {
        return integrations.reduce(function (acc, integrations) {
            if (acc.every(function (accIntegration) { return integrations.name !== accIntegration.name; })) {
                acc.push(integrations);
            }
            return acc;
        }, []);
    }
    /** Gets integration to install */
    function getIntegrationsToSetup(options) {
        var defaultIntegrations = (options.defaultIntegrations && __spread(options.defaultIntegrations)) || [];
        var userIntegrations = options.integrations;
        var integrations = __spread(filterDuplicates(defaultIntegrations));
        if (Array.isArray(userIntegrations)) {
            // Filter out integrations that are also included in user options
            integrations = __spread(integrations.filter(function (integrations) {
                return userIntegrations.every(function (userIntegration) { return userIntegration.name !== integrations.name; });
            }), filterDuplicates(userIntegrations));
        }
        else if (typeof userIntegrations === 'function') {
            integrations = userIntegrations(integrations);
            integrations = Array.isArray(integrations) ? integrations : [integrations];
        }
        // Make sure that if present, `Debug` integration will always run last
        var integrationsNames = integrations.map(function (i) { return i.name; });
        var alwaysLastToRun = 'Debug';
        if (integrationsNames.indexOf(alwaysLastToRun) !== -1) {
            integrations.push.apply(integrations, __spread(integrations.splice(integrationsNames.indexOf(alwaysLastToRun), 1)));
        }
        return integrations;
    }
    /** Setup given integration */
    function setupIntegration(integration) {
        if (installedIntegrations.indexOf(integration.name) !== -1) {
            return;
        }
        integration.setupOnce(addGlobalEventProcessor, getCurrentHub);
        installedIntegrations.push(integration.name);
        logger.log("Integration installed: " + integration.name);
    }
    /**
     * Given a list of integration instances this installs them all. When `withDefaults` is set to `true` then all default
     * integrations are added unless they were already provided before.
     * @param integrations array of integration instances
     * @param withDefault should enable default integrations
     */
    function setupIntegrations(options) {
        var integrations = {};
        getIntegrationsToSetup(options).forEach(function (integration) {
            integrations[integration.name] = integration;
            setupIntegration(integration);
        });
        // set the `initialized` flag so we don't run through the process again unecessarily; use `Object.defineProperty`
        // because by default it creates a property which is nonenumerable, which we want since `initialized` shouldn't be
        // considered a member of the index the way the actual integrations are
        addNonEnumerableProperty(integrations, 'initialized', true);
        return integrations;
    }

    var ALREADY_SEEN_ERROR = "Not capturing exception because it's already been captured.";
    /**
     * Base implementation for all JavaScript SDK clients.
     *
     * Call the constructor with the corresponding backend constructor and options
     * specific to the client subclass. To access these options later, use
     * {@link Client.getOptions}. Also, the Backend instance is available via
     * {@link Client.getBackend}.
     *
     * If a Dsn is specified in the options, it will be parsed and stored. Use
     * {@link Client.getDsn} to retrieve the Dsn at any moment. In case the Dsn is
     * invalid, the constructor will throw a {@link SentryException}. Note that
     * without a valid Dsn, the SDK will not send any events to Sentry.
     *
     * Before sending an event via the backend, it is passed through
     * {@link BaseClient._prepareEvent} to add SDK information and scope data
     * (breadcrumbs and context). To add more custom information, override this
     * method and extend the resulting prepared event.
     *
     * To issue automatically created events (e.g. via instrumentation), use
     * {@link Client.captureEvent}. It will prepare the event and pass it through
     * the callback lifecycle. To issue auto-breadcrumbs, use
     * {@link Client.addBreadcrumb}.
     *
     * @example
     * class NodeClient extends BaseClient<NodeBackend, NodeOptions> {
     *   public constructor(options: NodeOptions) {
     *     super(NodeBackend, options);
     *   }
     *
     *   // ...
     * }
     */
    var BaseClient = /** @class */ (function () {
        /**
         * Initializes this client instance.
         *
         * @param backendClass A constructor function to create the backend.
         * @param options Options for the client.
         */
        function BaseClient(backendClass, options) {
            /** Array of used integrations. */
            this._integrations = {};
            /** Number of calls being processed */
            this._numProcessing = 0;
            this._backend = new backendClass(options);
            this._options = options;
            if (options.dsn) {
                this._dsn = makeDsn(options.dsn);
            }
        }
        /**
         * @inheritDoc
         */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
        BaseClient.prototype.captureException = function (exception, hint, scope) {
            var _this = this;
            // ensure we haven't captured this very object before
            if (checkOrSetAlreadyCaught(exception)) {
                logger.log(ALREADY_SEEN_ERROR);
                return;
            }
            var eventId = hint && hint.event_id;
            this._process(this._getBackend()
                .eventFromException(exception, hint)
                .then(function (event) { return _this._captureEvent(event, hint, scope); })
                .then(function (result) {
                eventId = result;
            }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.captureMessage = function (message, level, hint, scope) {
            var _this = this;
            var eventId = hint && hint.event_id;
            var promisedEvent = isPrimitive(message)
                ? this._getBackend().eventFromMessage(String(message), level, hint)
                : this._getBackend().eventFromException(message, hint);
            this._process(promisedEvent
                .then(function (event) { return _this._captureEvent(event, hint, scope); })
                .then(function (result) {
                eventId = result;
            }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.captureEvent = function (event, hint, scope) {
            // ensure we haven't captured this very object before
            if (hint && hint.originalException && checkOrSetAlreadyCaught(hint.originalException)) {
                logger.log(ALREADY_SEEN_ERROR);
                return;
            }
            var eventId = hint && hint.event_id;
            this._process(this._captureEvent(event, hint, scope).then(function (result) {
                eventId = result;
            }));
            return eventId;
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.captureSession = function (session) {
            if (!this._isEnabled()) {
                logger.warn('SDK not enabled, will not capture session.');
                return;
            }
            if (!(typeof session.release === 'string')) {
                logger.warn('Discarded session because of missing or non-string release');
            }
            else {
                this._sendSession(session);
                // After sending, we set init false to indicate it's not the first occurrence
                session.update({ init: false });
            }
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.getDsn = function () {
            return this._dsn;
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.getOptions = function () {
            return this._options;
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.getTransport = function () {
            return this._getBackend().getTransport();
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.flush = function (timeout) {
            var _this = this;
            return this._isClientDoneProcessing(timeout).then(function (clientFinished) {
                return _this.getTransport()
                    .close(timeout)
                    .then(function (transportFlushed) { return clientFinished && transportFlushed; });
            });
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.close = function (timeout) {
            var _this = this;
            return this.flush(timeout).then(function (result) {
                _this.getOptions().enabled = false;
                return result;
            });
        };
        /**
         * Sets up the integrations
         */
        BaseClient.prototype.setupIntegrations = function () {
            if (this._isEnabled() && !this._integrations.initialized) {
                this._integrations = setupIntegrations(this._options);
            }
        };
        /**
         * @inheritDoc
         */
        BaseClient.prototype.getIntegration = function (integration) {
            try {
                return this._integrations[integration.id] || null;
            }
            catch (_oO) {
                logger.warn("Cannot retrieve integration " + integration.id + " from the current Client");
                return null;
            }
        };
        /** Updates existing session based on the provided event */
        BaseClient.prototype._updateSessionFromEvent = function (session, event) {
            var e_1, _a;
            var crashed = false;
            var errored = false;
            var exceptions = event.exception && event.exception.values;
            if (exceptions) {
                errored = true;
                try {
                    for (var exceptions_1 = __values(exceptions), exceptions_1_1 = exceptions_1.next(); !exceptions_1_1.done; exceptions_1_1 = exceptions_1.next()) {
                        var ex = exceptions_1_1.value;
                        var mechanism = ex.mechanism;
                        if (mechanism && mechanism.handled === false) {
                            crashed = true;
                            break;
                        }
                    }
                }
                catch (e_1_1) { e_1 = { error: e_1_1 }; }
                finally {
                    try {
                        if (exceptions_1_1 && !exceptions_1_1.done && (_a = exceptions_1.return)) _a.call(exceptions_1);
                    }
                    finally { if (e_1) throw e_1.error; }
                }
            }
            // A session is updated and that session update is sent in only one of the two following scenarios:
            // 1. Session with non terminal status and 0 errors + an error occurred -> Will set error count to 1 and send update
            // 2. Session with non terminal status and 1 error + a crash occurred -> Will set status crashed and send update
            var sessionNonTerminal = session.status === 'ok';
            var shouldUpdateAndSend = (sessionNonTerminal && session.errors === 0) || (sessionNonTerminal && crashed);
            if (shouldUpdateAndSend) {
                session.update(__assign(__assign({}, (crashed && { status: 'crashed' })), { errors: session.errors || Number(errored || crashed) }));
                this.captureSession(session);
            }
        };
        /** Deliver captured session to Sentry */
        BaseClient.prototype._sendSession = function (session) {
            this._getBackend().sendSession(session);
        };
        /**
         * Determine if the client is finished processing. Returns a promise because it will wait `timeout` ms before saying
         * "no" (resolving to `false`) in order to give the client a chance to potentially finish first.
         *
         * @param timeout The time, in ms, after which to resolve to `false` if the client is still busy. Passing `0` (or not
         * passing anything) will make the promise wait as long as it takes for processing to finish before resolving to
         * `true`.
         * @returns A promise which will resolve to `true` if processing is already done or finishes before the timeout, and
         * `false` otherwise
         */
        BaseClient.prototype._isClientDoneProcessing = function (timeout) {
            var _this = this;
            return new SyncPromise(function (resolve) {
                var ticked = 0;
                var tick = 1;
                var interval = setInterval(function () {
                    if (_this._numProcessing == 0) {
                        clearInterval(interval);
                        resolve(true);
                    }
                    else {
                        ticked += tick;
                        if (timeout && ticked >= timeout) {
                            clearInterval(interval);
                            resolve(false);
                        }
                    }
                }, tick);
            });
        };
        /** Returns the current backend. */
        BaseClient.prototype._getBackend = function () {
            return this._backend;
        };
        /** Determines whether this SDK is enabled and a valid Dsn is present. */
        BaseClient.prototype._isEnabled = function () {
            return this.getOptions().enabled !== false && this._dsn !== undefined;
        };
        /**
         * Adds common information to events.
         *
         * The information includes release and environment from `options`,
         * breadcrumbs and context (extra, tags and user) from the scope.
         *
         * Information that is already present in the event is never overwritten. For
         * nested objects, such as the context, keys are merged.
         *
         * @param event The original event.
         * @param hint May contain additional information about the original exception.
         * @param scope A scope containing event metadata.
         * @returns A new event with more information.
         */
        BaseClient.prototype._prepareEvent = function (event, scope, hint) {
            var _this = this;
            var _a = this.getOptions(), _b = _a.normalizeDepth, normalizeDepth = _b === void 0 ? 3 : _b, _c = _a.normalizeMaxBreadth, normalizeMaxBreadth = _c === void 0 ? 1000 : _c;
            var prepared = __assign(__assign({}, event), { event_id: event.event_id || (hint && hint.event_id ? hint.event_id : uuid4()), timestamp: event.timestamp || dateTimestampInSeconds() });
            this._applyClientOptions(prepared);
            this._applyIntegrationsMetadata(prepared);
            // If we have scope given to us, use it as the base for further modifications.
            // This allows us to prevent unnecessary copying of data if `captureContext` is not provided.
            var finalScope = scope;
            if (hint && hint.captureContext) {
                finalScope = Scope.clone(finalScope).update(hint.captureContext);
            }
            // We prepare the result here with a resolved Event.
            var result = resolvedSyncPromise(prepared);
            // This should be the last thing called, since we want that
            // {@link Hub.addEventProcessor} gets the finished prepared event.
            if (finalScope) {
                // In case we have a hub we reassign it.
                result = finalScope.applyToEvent(prepared, hint);
            }
            return result.then(function (evt) {
                if (evt) {
                    // TODO this is more of the hack trying to solve https://github.com/getsentry/sentry-javascript/issues/2809
                    // it is only attached as extra data to the event if the event somehow skips being normalized
                    evt.sdkProcessingMetadata = __assign(__assign({}, evt.sdkProcessingMetadata), { normalizeDepth: normalize(normalizeDepth) + " (" + typeof normalizeDepth + ")" });
                }
                if (typeof normalizeDepth === 'number' && normalizeDepth > 0) {
                    return _this._normalizeEvent(evt, normalizeDepth, normalizeMaxBreadth);
                }
                return evt;
            });
        };
        /**
         * Applies `normalize` function on necessary `Event` attributes to make them safe for serialization.
         * Normalized keys:
         * - `breadcrumbs.data`
         * - `user`
         * - `contexts`
         * - `extra`
         * @param event Event
         * @returns Normalized event
         */
        BaseClient.prototype._normalizeEvent = function (event, depth, maxBreadth) {
            if (!event) {
                return null;
            }
            var normalized = __assign(__assign(__assign(__assign(__assign({}, event), (event.breadcrumbs && {
                breadcrumbs: event.breadcrumbs.map(function (b) { return (__assign(__assign({}, b), (b.data && {
                    data: normalize(b.data, depth, maxBreadth),
                }))); }),
            })), (event.user && {
                user: normalize(event.user, depth, maxBreadth),
            })), (event.contexts && {
                contexts: normalize(event.contexts, depth, maxBreadth),
            })), (event.extra && {
                extra: normalize(event.extra, depth, maxBreadth),
            }));
            // event.contexts.trace stores information about a Transaction. Similarly,
            // event.spans[] stores information about child Spans. Given that a
            // Transaction is conceptually a Span, normalization should apply to both
            // Transactions and Spans consistently.
            // For now the decision is to skip normalization of Transactions and Spans,
            // so this block overwrites the normalized event to add back the original
            // Transaction information prior to normalization.
            if (event.contexts && event.contexts.trace) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                normalized.contexts.trace = event.contexts.trace;
            }
            normalized.sdkProcessingMetadata = __assign(__assign({}, normalized.sdkProcessingMetadata), { baseClientNormalized: true });
            return normalized;
        };
        /**
         *  Enhances event using the client configuration.
         *  It takes care of all "static" values like environment, release and `dist`,
         *  as well as truncating overly long values.
         * @param event event instance to be enhanced
         */
        BaseClient.prototype._applyClientOptions = function (event) {
            var options = this.getOptions();
            var environment = options.environment, release = options.release, dist = options.dist, _a = options.maxValueLength, maxValueLength = _a === void 0 ? 250 : _a;
            if (!('environment' in event)) {
                event.environment = 'environment' in options ? environment : 'production';
            }
            if (event.release === undefined && release !== undefined) {
                event.release = release;
            }
            if (event.dist === undefined && dist !== undefined) {
                event.dist = dist;
            }
            if (event.message) {
                event.message = truncate(event.message, maxValueLength);
            }
            var exception = event.exception && event.exception.values && event.exception.values[0];
            if (exception && exception.value) {
                exception.value = truncate(exception.value, maxValueLength);
            }
            var request = event.request;
            if (request && request.url) {
                request.url = truncate(request.url, maxValueLength);
            }
        };
        /**
         * This function adds all used integrations to the SDK info in the event.
         * @param event The event that will be filled with all integrations.
         */
        BaseClient.prototype._applyIntegrationsMetadata = function (event) {
            var integrationsArray = Object.keys(this._integrations);
            if (integrationsArray.length > 0) {
                event.sdk = event.sdk || {};
                event.sdk.integrations = __spread((event.sdk.integrations || []), integrationsArray);
            }
        };
        /**
         * Tells the backend to send this event
         * @param event The Sentry event to send
         */
        BaseClient.prototype._sendEvent = function (event) {
            this._getBackend().sendEvent(event);
        };
        /**
         * Processes the event and logs an error in case of rejection
         * @param event
         * @param hint
         * @param scope
         */
        BaseClient.prototype._captureEvent = function (event, hint, scope) {
            return this._processEvent(event, hint, scope).then(function (finalEvent) {
                return finalEvent.event_id;
            }, function (reason) {
                logger.error(reason);
                return undefined;
            });
        };
        /**
         * Processes an event (either error or message) and sends it to Sentry.
         *
         * This also adds breadcrumbs and context information to the event. However,
         * platform specific meta data (such as the User's IP address) must be added
         * by the SDK implementor.
         *
         *
         * @param event The event to send to Sentry.
         * @param hint May contain additional information about the original exception.
         * @param scope A scope containing event metadata.
         * @returns A SyncPromise that resolves with the event or rejects in case event was/will not be send.
         */
        BaseClient.prototype._processEvent = function (event, hint, scope) {
            var _this = this;
            // eslint-disable-next-line @typescript-eslint/unbound-method
            var _a = this.getOptions(), beforeSend = _a.beforeSend, sampleRate = _a.sampleRate;
            var transport = this.getTransport();
            function recordLostEvent(outcome, category) {
                if (transport.recordLostEvent) {
                    transport.recordLostEvent(outcome, category);
                }
            }
            if (!this._isEnabled()) {
                return rejectedSyncPromise(new SentryError('SDK not enabled, will not capture event.'));
            }
            var isTransaction = event.type === 'transaction';
            // 1.0 === 100% events are sent
            // 0.0 === 0% events are sent
            // Sampling for transaction happens somewhere else
            if (!isTransaction && typeof sampleRate === 'number' && Math.random() > sampleRate) {
                recordLostEvent('sample_rate', 'event');
                return rejectedSyncPromise(new SentryError("Discarding event because it's not included in the random sample (sampling rate = " + sampleRate + ")"));
            }
            return this._prepareEvent(event, scope, hint)
                .then(function (prepared) {
                if (prepared === null) {
                    recordLostEvent('event_processor', event.type || 'event');
                    throw new SentryError('An event processor returned null, will not send event.');
                }
                var isInternalException = hint && hint.data && hint.data.__sentry__ === true;
                if (isInternalException || isTransaction || !beforeSend) {
                    return prepared;
                }
                var beforeSendResult = beforeSend(prepared, hint);
                return _ensureBeforeSendRv(beforeSendResult);
            })
                .then(function (processedEvent) {
                if (processedEvent === null) {
                    recordLostEvent('before_send', event.type || 'event');
                    throw new SentryError('`beforeSend` returned `null`, will not send event.');
                }
                var session = scope && scope.getSession && scope.getSession();
                if (!isTransaction && session) {
                    _this._updateSessionFromEvent(session, processedEvent);
                }
                _this._sendEvent(processedEvent);
                return processedEvent;
            })
                .then(null, function (reason) {
                if (reason instanceof SentryError) {
                    throw reason;
                }
                _this.captureException(reason, {
                    data: {
                        __sentry__: true,
                    },
                    originalException: reason,
                });
                throw new SentryError("Event processing pipeline threw an error, original event will not be sent. Details have been sent as a new event.\nReason: " + reason);
            });
        };
        /**
         * Occupies the client with processing and event
         */
        BaseClient.prototype._process = function (promise) {
            var _this = this;
            this._numProcessing += 1;
            void promise.then(function (value) {
                _this._numProcessing -= 1;
                return value;
            }, function (reason) {
                _this._numProcessing -= 1;
                return reason;
            });
        };
        return BaseClient;
    }());
    /**
     * Verifies that return value of configured `beforeSend` is of expected type.
     */
    function _ensureBeforeSendRv(rv) {
        var nullErr = '`beforeSend` method has to return `null` or a valid event.';
        if (isThenable(rv)) {
            return rv.then(function (event) {
                if (!(isPlainObject(event) || event === null)) {
                    throw new SentryError(nullErr);
                }
                return event;
            }, function (e) {
                throw new SentryError("beforeSend rejected with " + e);
            });
        }
        else if (!(isPlainObject(rv) || rv === null)) {
            throw new SentryError(nullErr);
        }
        return rv;
    }

    /** Extract sdk info from from the API metadata */
    function getSdkMetadataForEnvelopeHeader(api) {
        if (!api.metadata || !api.metadata.sdk) {
            return;
        }
        var _a = api.metadata.sdk, name = _a.name, version = _a.version;
        return { name: name, version: version };
    }
    /**
     * Apply SdkInfo (name, version, packages, integrations) to the corresponding event key.
     * Merge with existing data if any.
     **/
    function enhanceEventWithSdkInfo(event, sdkInfo) {
        if (!sdkInfo) {
            return event;
        }
        event.sdk = event.sdk || {};
        event.sdk.name = event.sdk.name || sdkInfo.name;
        event.sdk.version = event.sdk.version || sdkInfo.version;
        event.sdk.integrations = __spread((event.sdk.integrations || []), (sdkInfo.integrations || []));
        event.sdk.packages = __spread((event.sdk.packages || []), (sdkInfo.packages || []));
        return event;
    }
    /** Creates an envelope from a Session */
    function createSessionEnvelope(session, api) {
        var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
        var envelopeHeaders = __assign(__assign({ sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: dsnToString(api.dsn) }));
        // I know this is hacky but we don't want to add `sessions` to request type since it's never rate limited
        var type = 'aggregates' in session ? 'sessions' : 'session';
        // TODO (v7) Have to cast type because envelope items do not accept a `SentryRequestType`
        var envelopeItem = [{ type: type }, session];
        var envelope = createEnvelope(envelopeHeaders, [envelopeItem]);
        return [envelope, type];
    }
    /** Creates a SentryRequest from a Session. */
    function sessionToSentryRequest(session, api) {
        var _a = __read(createSessionEnvelope(session, api), 2), envelope = _a[0], type = _a[1];
        return {
            body: serializeEnvelope(envelope),
            type: type,
            url: getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel),
        };
    }
    /**
     * Create an Envelope from an event. Note that this is duplicated from below,
     * but on purpose as this will be refactored in v7.
     */
    function createEventEnvelope(event, api) {
        var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
        var eventType = event.type || 'event';
        var transactionSampling = (event.sdkProcessingMetadata || {}).transactionSampling;
        var _a = transactionSampling || {}, samplingMethod = _a.method, sampleRate = _a.rate;
        // TODO: Below is a temporary hack in order to debug a serialization error - see
        // https://github.com/getsentry/sentry-javascript/issues/2809,
        // https://github.com/getsentry/sentry-javascript/pull/4425, and
        // https://github.com/getsentry/sentry-javascript/pull/4574.
        //
        // TL; DR: even though we normalize all events (which should prevent this), something is causing `JSON.stringify` to
        // throw a circular reference error.
        //
        // When it's time to remove it:
        // 1. Delete everything between here and where the request object `req` is created, EXCEPT the line deleting
        //    `sdkProcessingMetadata`
        // 2. Restore the original version of the request body, which is commented out
        // 3. Search for either of the PR URLs above and pull out the companion hacks in the browser playwright tests and the
        //    baseClient tests in this package
        enhanceEventWithSdkInfo(event, api.metadata.sdk);
        event.tags = event.tags || {};
        event.extra = event.extra || {};
        // In theory, all events should be marked as having gone through normalization and so
        // we should never set this tag/extra data
        if (!(event.sdkProcessingMetadata && event.sdkProcessingMetadata.baseClientNormalized)) {
            event.tags.skippedNormalization = true;
            event.extra.normalizeDepth = event.sdkProcessingMetadata ? event.sdkProcessingMetadata.normalizeDepth : 'unset';
        }
        // prevent this data from being sent to sentry
        // TODO: This is NOT part of the hack - DO NOT DELETE
        delete event.sdkProcessingMetadata;
        var envelopeHeaders = __assign(__assign({ event_id: event.event_id, sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: dsnToString(api.dsn) }));
        var eventItem = [
            {
                type: eventType,
                sample_rates: [{ id: samplingMethod, rate: sampleRate }],
            },
            event,
        ];
        return createEnvelope(envelopeHeaders, [eventItem]);
    }
    /** Creates a SentryRequest from an event. */
    function eventToSentryRequest(event, api) {
        var sdkInfo = getSdkMetadataForEnvelopeHeader(api);
        var eventType = event.type || 'event';
        var useEnvelope = eventType === 'transaction' || !!api.tunnel;
        var transactionSampling = (event.sdkProcessingMetadata || {}).transactionSampling;
        var _a = transactionSampling || {}, samplingMethod = _a.method, sampleRate = _a.rate;
        // TODO: Below is a temporary hack in order to debug a serialization error - see
        // https://github.com/getsentry/sentry-javascript/issues/2809,
        // https://github.com/getsentry/sentry-javascript/pull/4425, and
        // https://github.com/getsentry/sentry-javascript/pull/4574.
        //
        // TL; DR: even though we normalize all events (which should prevent this), something is causing `JSON.stringify` to
        // throw a circular reference error.
        //
        // When it's time to remove it:
        // 1. Delete everything between here and where the request object `req` is created, EXCEPT the line deleting
        //    `sdkProcessingMetadata`
        // 2. Restore the original version of the request body, which is commented out
        // 3. Search for either of the PR URLs above and pull out the companion hacks in the browser playwright tests and the
        //    baseClient tests in this package
        enhanceEventWithSdkInfo(event, api.metadata.sdk);
        event.tags = event.tags || {};
        event.extra = event.extra || {};
        // In theory, all events should be marked as having gone through normalization and so
        // we should never set this tag/extra data
        if (!(event.sdkProcessingMetadata && event.sdkProcessingMetadata.baseClientNormalized)) {
            event.tags.skippedNormalization = true;
            event.extra.normalizeDepth = event.sdkProcessingMetadata ? event.sdkProcessingMetadata.normalizeDepth : 'unset';
        }
        // prevent this data from being sent to sentry
        // TODO: This is NOT part of the hack - DO NOT DELETE
        delete event.sdkProcessingMetadata;
        var body;
        try {
            // 99.9% of events should get through just fine - no change in behavior for them
            body = JSON.stringify(event);
        }
        catch (err) {
            // Record data about the error without replacing original event data, then force renormalization
            event.tags.JSONStringifyError = true;
            event.extra.JSONStringifyError = err;
            try {
                body = JSON.stringify(normalize(event));
            }
            catch (newErr) {
                // At this point even renormalization hasn't worked, meaning something about the event data has gone very wrong.
                // Time to cut our losses and record only the new error. With luck, even in the problematic cases we're trying to
                // debug with this hack, we won't ever land here.
                var innerErr = newErr;
                body = JSON.stringify({
                    message: 'JSON.stringify error after renormalization',
                    // setting `extra: { innerErr }` here for some reason results in an empty object, so unpack manually
                    extra: { message: innerErr.message, stack: innerErr.stack },
                });
            }
        }
        var req = {
            // this is the relevant line of code before the hack was added, to make it easy to undo said hack once we've solved
            // the mystery
            // body: JSON.stringify(sdkInfo ? enhanceEventWithSdkInfo(event, api.metadata.sdk) : event),
            body: body,
            type: eventType,
            url: useEnvelope
                ? getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel)
                : getStoreEndpointWithUrlEncodedAuth(api.dsn),
        };
        // https://develop.sentry.dev/sdk/envelopes/
        // Since we don't need to manipulate envelopes nor store them, there is no
        // exported concept of an Envelope with operations including serialization and
        // deserialization. Instead, we only implement a minimal subset of the spec to
        // serialize events inline here.
        if (useEnvelope) {
            var envelopeHeaders = __assign(__assign({ event_id: event.event_id, sent_at: new Date().toISOString() }, (sdkInfo && { sdk: sdkInfo })), (!!api.tunnel && { dsn: dsnToString(api.dsn) }));
            var eventItem = [
                {
                    type: eventType,
                    sample_rates: [{ id: samplingMethod, rate: sampleRate }],
                },
                req.body,
            ];
            var envelope = createEnvelope(envelopeHeaders, [eventItem]);
            req.body = serializeEnvelope(envelope);
        }
        return req;
    }

    /** Noop transport */
    var NoopTransport = /** @class */ (function () {
        function NoopTransport() {
        }
        /**
         * @inheritDoc
         */
        NoopTransport.prototype.sendEvent = function (_) {
            return resolvedSyncPromise({
                reason: 'NoopTransport: Event has been skipped because no Dsn is configured.',
                status: 'skipped',
            });
        };
        /**
         * @inheritDoc
         */
        NoopTransport.prototype.close = function (_) {
            return resolvedSyncPromise(true);
        };
        return NoopTransport;
    }());

    /**
     * This is the base implemention of a Backend.
     * @hidden
     */
    var BaseBackend = /** @class */ (function () {
        /** Creates a new backend instance. */
        function BaseBackend(options) {
            this._options = options;
            if (!this._options.dsn) {
                logger.warn('No DSN provided, backend will not do anything.');
            }
            this._transport = this._setupTransport();
        }
        /**
         * @inheritDoc
         */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/explicit-module-boundary-types
        BaseBackend.prototype.eventFromException = function (_exception, _hint) {
            throw new SentryError('Backend has to implement `eventFromException` method');
        };
        /**
         * @inheritDoc
         */
        BaseBackend.prototype.eventFromMessage = function (_message, _level, _hint) {
            throw new SentryError('Backend has to implement `eventFromMessage` method');
        };
        /**
         * @inheritDoc
         */
        BaseBackend.prototype.sendEvent = function (event) {
            // TODO(v7): Remove the if-else
            if (this._newTransport &&
                this._options.dsn &&
                this._options._experiments &&
                this._options._experiments.newTransport) {
                var api = initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
                var env = createEventEnvelope(event, api);
                void this._newTransport.send(env).then(null, function (reason) {
                    logger.error('Error while sending event:', reason);
                });
            }
            else {
                void this._transport.sendEvent(event).then(null, function (reason) {
                    logger.error('Error while sending event:', reason);
                });
            }
        };
        /**
         * @inheritDoc
         */
        BaseBackend.prototype.sendSession = function (session) {
            if (!this._transport.sendSession) {
                logger.warn("Dropping session because custom transport doesn't implement sendSession");
                return;
            }
            // TODO(v7): Remove the if-else
            if (this._newTransport &&
                this._options.dsn &&
                this._options._experiments &&
                this._options._experiments.newTransport) {
                var api = initAPIDetails(this._options.dsn, this._options._metadata, this._options.tunnel);
                var _a = __read(createSessionEnvelope(session, api), 1), env = _a[0];
                void this._newTransport.send(env).then(null, function (reason) {
                    logger.error('Error while sending session:', reason);
                });
            }
            else {
                void this._transport.sendSession(session).then(null, function (reason) {
                    logger.error('Error while sending session:', reason);
                });
            }
        };
        /**
         * @inheritDoc
         */
        BaseBackend.prototype.getTransport = function () {
            return this._transport;
        };
        /**
         * Sets up the transport so it can be used later to send requests.
         */
        BaseBackend.prototype._setupTransport = function () {
            return new NoopTransport();
        };
        return BaseBackend;
    }());

    /**
     * Internal function to create a new SDK client instance. The client is
     * installed and then bound to the current scope.
     *
     * @param clientClass The client class to instantiate.
     * @param options Options to pass to the client.
     */
    function initAndBind(clientClass, options) {
        if (options.debug === true) {
            if (IS_DEBUG_BUILD$1) {
                logger.enable();
            }
            else {
                // use `console.warn` rather than `logger.warn` since by non-debug bundles have all `logger.x` statements stripped
                // eslint-disable-next-line no-console
                console.warn('[Sentry] Cannot initialize SDK with `debug` option using a non-debug bundle.');
            }
        }
        var hub = getCurrentHub();
        var scope = hub.getScope();
        if (scope) {
            scope.update(options.initialScope);
        }
        var client = new clientClass(options);
        hub.bindClient(client);
    }

    var DEFAULT_TRANSPORT_BUFFER_SIZE = 30;
    /**
     * Creates a `NewTransport`
     *
     * @param options
     * @param makeRequest
     */
    function createTransport(options, makeRequest, buffer) {
        if (buffer === void 0) { buffer = makePromiseBuffer(options.bufferSize || DEFAULT_TRANSPORT_BUFFER_SIZE); }
        var rateLimits = {};
        var flush = function (timeout) { return buffer.drain(timeout); };
        function send(envelope) {
            var envCategory = getEnvelopeType(envelope);
            var category = envCategory === 'event' ? 'error' : envCategory;
            var request = {
                category: category,
                body: serializeEnvelope(envelope),
            };
            // Don't add to buffer if transport is already rate-limited
            if (isRateLimited(rateLimits, category)) {
                return rejectedSyncPromise({
                    status: 'rate_limit',
                    reason: getRateLimitReason(rateLimits, category),
                });
            }
            var requestTask = function () {
                return makeRequest(request).then(function (_a) {
                    var body = _a.body, headers = _a.headers, reason = _a.reason, statusCode = _a.statusCode;
                    var status = eventStatusFromHttpCode(statusCode);
                    if (headers) {
                        rateLimits = updateRateLimits(rateLimits, headers);
                    }
                    if (status === 'success') {
                        return resolvedSyncPromise({ status: status, reason: reason });
                    }
                    return rejectedSyncPromise({
                        status: status,
                        reason: reason ||
                            body ||
                            (status === 'rate_limit' ? getRateLimitReason(rateLimits, category) : 'Unknown transport error'),
                    });
                });
            };
            return buffer.add(requestTask);
        }
        return {
            send: send,
            flush: flush,
        };
    }
    function getRateLimitReason(rateLimits, category) {
        return "Too many " + category + " requests, backing off until: " + new Date(disabledUntil(rateLimits, category)).toISOString();
    }

    var SDK_VERSION = '6.19.7';

    var originalFunctionToString;
    /** Patch toString calls to return proper name for wrapped functions */
    var FunctionToString = /** @class */ (function () {
        function FunctionToString() {
            /**
             * @inheritDoc
             */
            this.name = FunctionToString.id;
        }
        /**
         * @inheritDoc
         */
        FunctionToString.prototype.setupOnce = function () {
            // eslint-disable-next-line @typescript-eslint/unbound-method
            originalFunctionToString = Function.prototype.toString;
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            Function.prototype.toString = function () {
                var args = [];
                for (var _i = 0; _i < arguments.length; _i++) {
                    args[_i] = arguments[_i];
                }
                var context = getOriginalFunction(this) || this;
                return originalFunctionToString.apply(context, args);
            };
        };
        /**
         * @inheritDoc
         */
        FunctionToString.id = 'FunctionToString';
        return FunctionToString;
    }());

    // "Script error." is hard coded into browsers for errors that it can't read.
    // this is the result of a script being pulled in from an external domain and CORS.
    var DEFAULT_IGNORE_ERRORS = [/^Script error\.?$/, /^Javascript error: Script error\.? on line 0$/];
    /** Inbound filters configurable by the user */
    var InboundFilters = /** @class */ (function () {
        function InboundFilters(_options) {
            if (_options === void 0) { _options = {}; }
            this._options = _options;
            /**
             * @inheritDoc
             */
            this.name = InboundFilters.id;
        }
        /**
         * @inheritDoc
         */
        InboundFilters.prototype.setupOnce = function (addGlobalEventProcessor, getCurrentHub) {
            addGlobalEventProcessor(function (event) {
                var hub = getCurrentHub();
                if (hub) {
                    var self_1 = hub.getIntegration(InboundFilters);
                    if (self_1) {
                        var client = hub.getClient();
                        var clientOptions = client ? client.getOptions() : {};
                        var options = _mergeOptions(self_1._options, clientOptions);
                        return _shouldDropEvent$1(event, options) ? null : event;
                    }
                }
                return event;
            });
        };
        /**
         * @inheritDoc
         */
        InboundFilters.id = 'InboundFilters';
        return InboundFilters;
    }());
    /** JSDoc */
    function _mergeOptions(internalOptions, clientOptions) {
        if (internalOptions === void 0) { internalOptions = {}; }
        if (clientOptions === void 0) { clientOptions = {}; }
        return {
            allowUrls: __spread((internalOptions.whitelistUrls || []), (internalOptions.allowUrls || []), (clientOptions.whitelistUrls || []), (clientOptions.allowUrls || [])),
            denyUrls: __spread((internalOptions.blacklistUrls || []), (internalOptions.denyUrls || []), (clientOptions.blacklistUrls || []), (clientOptions.denyUrls || [])),
            ignoreErrors: __spread((internalOptions.ignoreErrors || []), (clientOptions.ignoreErrors || []), DEFAULT_IGNORE_ERRORS),
            ignoreInternal: internalOptions.ignoreInternal !== undefined ? internalOptions.ignoreInternal : true,
        };
    }
    /** JSDoc */
    function _shouldDropEvent$1(event, options) {
        if (options.ignoreInternal && _isSentryError(event)) {
            IS_DEBUG_BUILD$1 &&
                logger.warn("Event dropped due to being internal Sentry Error.\nEvent: " + getEventDescription(event));
            return true;
        }
        if (_isIgnoredError(event, options.ignoreErrors)) {
            IS_DEBUG_BUILD$1 &&
                logger.warn("Event dropped due to being matched by `ignoreErrors` option.\nEvent: " + getEventDescription(event));
            return true;
        }
        if (_isDeniedUrl(event, options.denyUrls)) {
            IS_DEBUG_BUILD$1 &&
                logger.warn("Event dropped due to being matched by `denyUrls` option.\nEvent: " + getEventDescription(event) + ".\nUrl: " + _getEventFilterUrl(event));
            return true;
        }
        if (!_isAllowedUrl(event, options.allowUrls)) {
            IS_DEBUG_BUILD$1 &&
                logger.warn("Event dropped due to not being matched by `allowUrls` option.\nEvent: " + getEventDescription(event) + ".\nUrl: " + _getEventFilterUrl(event));
            return true;
        }
        return false;
    }
    function _isIgnoredError(event, ignoreErrors) {
        if (!ignoreErrors || !ignoreErrors.length) {
            return false;
        }
        return _getPossibleEventMessages(event).some(function (message) {
            return ignoreErrors.some(function (pattern) { return isMatchingPattern(message, pattern); });
        });
    }
    function _isDeniedUrl(event, denyUrls) {
        // TODO: Use Glob instead?
        if (!denyUrls || !denyUrls.length) {
            return false;
        }
        var url = _getEventFilterUrl(event);
        return !url ? false : denyUrls.some(function (pattern) { return isMatchingPattern(url, pattern); });
    }
    function _isAllowedUrl(event, allowUrls) {
        // TODO: Use Glob instead?
        if (!allowUrls || !allowUrls.length) {
            return true;
        }
        var url = _getEventFilterUrl(event);
        return !url ? true : allowUrls.some(function (pattern) { return isMatchingPattern(url, pattern); });
    }
    function _getPossibleEventMessages(event) {
        if (event.message) {
            return [event.message];
        }
        if (event.exception) {
            try {
                var _a = (event.exception.values && event.exception.values[0]) || {}, _b = _a.type, type = _b === void 0 ? '' : _b, _c = _a.value, value = _c === void 0 ? '' : _c;
                return ["" + value, type + ": " + value];
            }
            catch (oO) {
                IS_DEBUG_BUILD$1 && logger.error("Cannot extract message for event " + getEventDescription(event));
                return [];
            }
        }
        return [];
    }
    function _isSentryError(event) {
        try {
            // @ts-ignore can't be a sentry error if undefined
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            return event.exception.values[0].type === 'SentryError';
        }
        catch (e) {
            // ignore
        }
        return false;
    }
    function _getLastValidUrl(frames) {
        if (frames === void 0) { frames = []; }
        for (var i = frames.length - 1; i >= 0; i--) {
            var frame = frames[i];
            if (frame && frame.filename !== '<anonymous>' && frame.filename !== '[native code]') {
                return frame.filename || null;
            }
        }
        return null;
    }
    function _getEventFilterUrl(event) {
        try {
            if (event.stacktrace) {
                return _getLastValidUrl(event.stacktrace.frames);
            }
            var frames_1;
            try {
                // @ts-ignore we only care about frames if the whole thing here is defined
                frames_1 = event.exception.values[0].stacktrace.frames;
            }
            catch (e) {
                // ignore
            }
            return frames_1 ? _getLastValidUrl(frames_1) : null;
        }
        catch (oO) {
            IS_DEBUG_BUILD$1 && logger.error("Cannot extract url for event " + getEventDescription(event));
            return null;
        }
    }

    var CoreIntegrations = /*#__PURE__*/Object.freeze({
        __proto__: null,
        FunctionToString: FunctionToString,
        InboundFilters: InboundFilters
    });

    // global reference to slice
    var UNKNOWN_FUNCTION = '?';
    var OPERA10_PRIORITY = 10;
    var OPERA11_PRIORITY = 20;
    var CHROME_PRIORITY = 30;
    var WINJS_PRIORITY = 40;
    var GECKO_PRIORITY = 50;
    function createFrame(filename, func, lineno, colno) {
        var frame = {
            filename: filename,
            function: func,
            // All browser frames are considered in_app
            in_app: true,
        };
        if (lineno !== undefined) {
            frame.lineno = lineno;
        }
        if (colno !== undefined) {
            frame.colno = colno;
        }
        return frame;
    }
    // Chromium based browsers: Chrome, Brave, new Opera, new Edge
    var chromeRegex = /^\s*at (?:(.*?) ?\((?:address at )?)?((?:file|https?|blob|chrome-extension|address|native|eval|webpack|<anonymous>|[-a-z]+:|.*bundle|\/).*?)(?::(\d+))?(?::(\d+))?\)?\s*$/i;
    var chromeEvalRegex = /\((\S*)(?::(\d+))(?::(\d+))\)/;
    var chrome = function (line) {
        var parts = chromeRegex.exec(line);
        if (parts) {
            var isEval = parts[2] && parts[2].indexOf('eval') === 0; // start of line
            if (isEval) {
                var subMatch = chromeEvalRegex.exec(parts[2]);
                if (subMatch) {
                    // throw out eval line/column and use top-most line/column number
                    parts[2] = subMatch[1]; // url
                    parts[3] = subMatch[2]; // line
                    parts[4] = subMatch[3]; // column
                }
            }
            // Kamil: One more hack won't hurt us right? Understanding and adding more rules on top of these regexps right now
            // would be way too time consuming. (TODO: Rewrite whole RegExp to be more readable)
            var _a = __read(extractSafariExtensionDetails(parts[1] || UNKNOWN_FUNCTION, parts[2]), 2), func = _a[0], filename = _a[1];
            return createFrame(filename, func, parts[3] ? +parts[3] : undefined, parts[4] ? +parts[4] : undefined);
        }
        return;
    };
    var chromeStackParser = [CHROME_PRIORITY, chrome];
    // gecko regex: `(?:bundle|\d+\.js)`: `bundle` is for react native, `\d+\.js` also but specifically for ram bundles because it
    // generates filenames without a prefix like `file://` the filenames in the stacktrace are just 42.js
    // We need this specific case for now because we want no other regex to match.
    var geckoREgex = /^\s*(.*?)(?:\((.*?)\))?(?:^|@)?((?:file|https?|blob|chrome|webpack|resource|moz-extension|capacitor).*?:\/.*?|\[native code\]|[^@]*(?:bundle|\d+\.js)|\/[\w\-. /=]+)(?::(\d+))?(?::(\d+))?\s*$/i;
    var geckoEvalRegex = /(\S+) line (\d+)(?: > eval line \d+)* > eval/i;
    var gecko = function (line) {
        var _a;
        var parts = geckoREgex.exec(line);
        if (parts) {
            var isEval = parts[3] && parts[3].indexOf(' > eval') > -1;
            if (isEval) {
                var subMatch = geckoEvalRegex.exec(parts[3]);
                if (subMatch) {
                    // throw out eval line/column and use top-most line number
                    parts[1] = parts[1] || 'eval';
                    parts[3] = subMatch[1];
                    parts[4] = subMatch[2];
                    parts[5] = ''; // no column when eval
                }
            }
            var filename = parts[3];
            var func = parts[1] || UNKNOWN_FUNCTION;
            _a = __read(extractSafariExtensionDetails(func, filename), 2), func = _a[0], filename = _a[1];
            return createFrame(filename, func, parts[4] ? +parts[4] : undefined, parts[5] ? +parts[5] : undefined);
        }
        return;
    };
    var geckoStackParser = [GECKO_PRIORITY, gecko];
    var winjsRegex = /^\s*at (?:((?:\[object object\])?.+) )?\(?((?:file|ms-appx|https?|webpack|blob):.*?):(\d+)(?::(\d+))?\)?\s*$/i;
    var winjs = function (line) {
        var parts = winjsRegex.exec(line);
        return parts
            ? createFrame(parts[2], parts[1] || UNKNOWN_FUNCTION, +parts[3], parts[4] ? +parts[4] : undefined)
            : undefined;
    };
    var winjsStackParser = [WINJS_PRIORITY, winjs];
    var opera10Regex = / line (\d+).*script (?:in )?(\S+)(?:: in function (\S+))?$/i;
    var opera10 = function (line) {
        var parts = opera10Regex.exec(line);
        return parts ? createFrame(parts[2], parts[3] || UNKNOWN_FUNCTION, +parts[1]) : undefined;
    };
    var opera10StackParser = [OPERA10_PRIORITY, opera10];
    var opera11Regex = / line (\d+), column (\d+)\s*(?:in (?:<anonymous function: ([^>]+)>|([^)]+))\(.*\))? in (.*):\s*$/i;
    var opera11 = function (line) {
        var parts = opera11Regex.exec(line);
        return parts ? createFrame(parts[5], parts[3] || parts[4] || UNKNOWN_FUNCTION, +parts[1], +parts[2]) : undefined;
    };
    var opera11StackParser = [OPERA11_PRIORITY, opera11];
    /**
     * Safari web extensions, starting version unknown, can produce "frames-only" stacktraces.
     * What it means, is that instead of format like:
     *
     * Error: wat
     *   at function@url:row:col
     *   at function@url:row:col
     *   at function@url:row:col
     *
     * it produces something like:
     *
     *   function@url:row:col
     *   function@url:row:col
     *   function@url:row:col
     *
     * Because of that, it won't be captured by `chrome` RegExp and will fall into `Gecko` branch.
     * This function is extracted so that we can use it in both places without duplicating the logic.
     * Unfortunately "just" changing RegExp is too complicated now and making it pass all tests
     * and fix this case seems like an impossible, or at least way too time-consuming task.
     */
    var extractSafariExtensionDetails = function (func, filename) {
        var isSafariExtension = func.indexOf('safari-extension') !== -1;
        var isSafariWebExtension = func.indexOf('safari-web-extension') !== -1;
        return isSafariExtension || isSafariWebExtension
            ? [
                func.indexOf('@') !== -1 ? func.split('@')[0] : UNKNOWN_FUNCTION,
                isSafariExtension ? "safari-extension:" + filename : "safari-web-extension:" + filename,
            ]
            : [func, filename];
    };

    /**
     * This function creates an exception from an TraceKitStackTrace
     * @param stacktrace TraceKitStackTrace that will be converted to an exception
     * @hidden
     */
    function exceptionFromError(ex) {
        // Get the frames first since Opera can lose the stack if we touch anything else first
        var frames = parseStackFrames(ex);
        var exception = {
            type: ex && ex.name,
            value: extractMessage(ex),
        };
        if (frames.length) {
            exception.stacktrace = { frames: frames };
        }
        if (exception.type === undefined && exception.value === '') {
            exception.value = 'Unrecoverable error caught';
        }
        return exception;
    }
    /**
     * @hidden
     */
    function eventFromPlainObject(exception, syntheticException, isUnhandledRejection) {
        var event = {
            exception: {
                values: [
                    {
                        type: isEvent(exception) ? exception.constructor.name : isUnhandledRejection ? 'UnhandledRejection' : 'Error',
                        value: "Non-Error " + (isUnhandledRejection ? 'promise rejection' : 'exception') + " captured with keys: " + extractExceptionKeysForMessage(exception),
                    },
                ],
            },
            extra: {
                __serialized__: normalizeToSize(exception),
            },
        };
        if (syntheticException) {
            var frames_1 = parseStackFrames(syntheticException);
            if (frames_1.length) {
                event.stacktrace = { frames: frames_1 };
            }
        }
        return event;
    }
    /**
     * @hidden
     */
    function eventFromError(ex) {
        return {
            exception: {
                values: [exceptionFromError(ex)],
            },
        };
    }
    /** Parses stack frames from an error */
    function parseStackFrames(ex) {
        // Access and store the stacktrace property before doing ANYTHING
        // else to it because Opera is not very good at providing it
        // reliably in other circumstances.
        var stacktrace = ex.stacktrace || ex.stack || '';
        var popSize = getPopSize(ex);
        try {
            return createStackParser(opera10StackParser, opera11StackParser, chromeStackParser, winjsStackParser, geckoStackParser)(stacktrace, popSize);
        }
        catch (e) {
            // no-empty
        }
        return [];
    }
    // Based on our own mapping pattern - https://github.com/getsentry/sentry/blob/9f08305e09866c8bd6d0c24f5b0aabdd7dd6c59c/src/sentry/lang/javascript/errormapping.py#L83-L108
    var reactMinifiedRegexp = /Minified React error #\d+;/i;
    function getPopSize(ex) {
        if (ex) {
            if (typeof ex.framesToPop === 'number') {
                return ex.framesToPop;
            }
            if (reactMinifiedRegexp.test(ex.message)) {
                return 1;
            }
        }
        return 0;
    }
    /**
     * There are cases where stacktrace.message is an Event object
     * https://github.com/getsentry/sentry-javascript/issues/1949
     * In this specific case we try to extract stacktrace.message.error.message
     */
    function extractMessage(ex) {
        var message = ex && ex.message;
        if (!message) {
            return 'No error message';
        }
        if (message.error && typeof message.error.message === 'string') {
            return message.error.message;
        }
        return message;
    }
    /**
     * Creates an {@link Event} from all inputs to `captureException` and non-primitive inputs to `captureMessage`.
     * @hidden
     */
    function eventFromException(exception, hint, attachStacktrace) {
        var syntheticException = (hint && hint.syntheticException) || undefined;
        var event = eventFromUnknownInput(exception, syntheticException, attachStacktrace);
        addExceptionMechanism(event); // defaults to { type: 'generic', handled: true }
        event.level = exports.Severity.Error;
        if (hint && hint.event_id) {
            event.event_id = hint.event_id;
        }
        return resolvedSyncPromise(event);
    }
    /**
     * Builds and Event from a Message
     * @hidden
     */
    function eventFromMessage(message, level, hint, attachStacktrace) {
        if (level === void 0) { level = exports.Severity.Info; }
        var syntheticException = (hint && hint.syntheticException) || undefined;
        var event = eventFromString(message, syntheticException, attachStacktrace);
        event.level = level;
        if (hint && hint.event_id) {
            event.event_id = hint.event_id;
        }
        return resolvedSyncPromise(event);
    }
    /**
     * @hidden
     */
    function eventFromUnknownInput(exception, syntheticException, attachStacktrace, isUnhandledRejection) {
        var event;
        if (isErrorEvent(exception) && exception.error) {
            // If it is an ErrorEvent with `error` property, extract it to get actual Error
            var errorEvent = exception;
            return eventFromError(errorEvent.error);
        }
        // If it is a `DOMError` (which is a legacy API, but still supported in some browsers) then we just extract the name
        // and message, as it doesn't provide anything else. According to the spec, all `DOMExceptions` should also be
        // `Error`s, but that's not the case in IE11, so in that case we treat it the same as we do a `DOMError`.
        //
        // https://developer.mozilla.org/en-US/docs/Web/API/DOMError
        // https://developer.mozilla.org/en-US/docs/Web/API/DOMException
        // https://webidl.spec.whatwg.org/#es-DOMException-specialness
        if (isDOMError(exception) || isDOMException(exception)) {
            var domException = exception;
            if ('stack' in exception) {
                event = eventFromError(exception);
            }
            else {
                var name_1 = domException.name || (isDOMError(domException) ? 'DOMError' : 'DOMException');
                var message = domException.message ? name_1 + ": " + domException.message : name_1;
                event = eventFromString(message, syntheticException, attachStacktrace);
                addExceptionTypeValue(event, message);
            }
            if ('code' in domException) {
                event.tags = __assign(__assign({}, event.tags), { 'DOMException.code': "" + domException.code });
            }
            return event;
        }
        if (isError(exception)) {
            // we have a real Error object, do nothing
            return eventFromError(exception);
        }
        if (isPlainObject(exception) || isEvent(exception)) {
            // If it's a plain object or an instance of `Event` (the built-in JS kind, not this SDK's `Event` type), serialize
            // it manually. This will allow us to group events based on top-level keys which is much better than creating a new
            // group on any key/value change.
            var objectException = exception;
            event = eventFromPlainObject(objectException, syntheticException, isUnhandledRejection);
            addExceptionMechanism(event, {
                synthetic: true,
            });
            return event;
        }
        // If none of previous checks were valid, then it means that it's not:
        // - an instance of DOMError
        // - an instance of DOMException
        // - an instance of Event
        // - an instance of Error
        // - a valid ErrorEvent (one with an error property)
        // - a plain Object
        //
        // So bail out and capture it as a simple message:
        event = eventFromString(exception, syntheticException, attachStacktrace);
        addExceptionTypeValue(event, "" + exception, undefined);
        addExceptionMechanism(event, {
            synthetic: true,
        });
        return event;
    }
    /**
     * @hidden
     */
    function eventFromString(input, syntheticException, attachStacktrace) {
        var event = {
            message: input,
        };
        if (attachStacktrace && syntheticException) {
            var frames_2 = parseStackFrames(syntheticException);
            if (frames_2.length) {
                event.stacktrace = { frames: frames_2 };
            }
        }
        return event;
    }

    /*
     * This file defines flags and constants that can be modified during compile time in order to facilitate tree shaking
     * for users.
     *
     * Debug flags need to be declared in each package individually and must not be imported across package boundaries,
     * because some build tools have trouble tree-shaking imported guards.
     *
     * As a convention, we define debug flags in a `flags.ts` file in the root of a package's `src` folder.
     *
     * Debug flag files will contain "magic strings" like `true` that may get replaced with actual values during
     * our, or the user's build process. Take care when introducing new flags - they must not throw if they are not
     * replaced.
     */
    /** Flag that is true for debug builds, false otherwise. */
    var IS_DEBUG_BUILD = true;

    var global$4 = getGlobalObject();
    var cachedFetchImpl;
    /**
     * A special usecase for incorrectly wrapped Fetch APIs in conjunction with ad-blockers.
     * Whenever someone wraps the Fetch API and returns the wrong promise chain,
     * this chain becomes orphaned and there is no possible way to capture it's rejections
     * other than allowing it bubble up to this very handler. eg.
     *
     * const f = window.fetch;
     * window.fetch = function () {
     *   const p = f.apply(this, arguments);
     *
     *   p.then(function() {
     *     console.log('hi.');
     *   });
     *
     *   return p;
     * }
     *
     * `p.then(function () { ... })` is producing a completely separate promise chain,
     * however, what's returned is `p` - the result of original `fetch` call.
     *
     * This mean, that whenever we use the Fetch API to send our own requests, _and_
     * some ad-blocker blocks it, this orphaned chain will _always_ reject,
     * effectively causing another event to be captured.
     * This makes a whole process become an infinite loop, which we need to somehow
     * deal with, and break it in one way or another.
     *
     * To deal with this issue, we are making sure that we _always_ use the real
     * browser Fetch API, instead of relying on what `window.fetch` exposes.
     * The only downside to this would be missing our own requests as breadcrumbs,
     * but because we are already not doing this, it should be just fine.
     *
     * Possible failed fetch error messages per-browser:
     *
     * Chrome:  Failed to fetch
     * Edge:    Failed to Fetch
     * Firefox: NetworkError when attempting to fetch resource
     * Safari:  resource blocked by content blocker
     */
    function getNativeFetchImplementation() {
        if (cachedFetchImpl) {
            return cachedFetchImpl;
        }
        /* eslint-disable @typescript-eslint/unbound-method */
        // Fast path to avoid DOM I/O
        if (isNativeFetch(global$4.fetch)) {
            return (cachedFetchImpl = global$4.fetch.bind(global$4));
        }
        var document = global$4.document;
        var fetchImpl = global$4.fetch;
        // eslint-disable-next-line deprecation/deprecation
        if (document && typeof document.createElement === 'function') {
            try {
                var sandbox = document.createElement('iframe');
                sandbox.hidden = true;
                document.head.appendChild(sandbox);
                var contentWindow = sandbox.contentWindow;
                if (contentWindow && contentWindow.fetch) {
                    fetchImpl = contentWindow.fetch;
                }
                document.head.removeChild(sandbox);
            }
            catch (e) {
                logger.warn('Could not create sandbox iframe for pure fetch check, bailing to window.fetch: ', e);
            }
        }
        return (cachedFetchImpl = fetchImpl.bind(global$4));
        /* eslint-enable @typescript-eslint/unbound-method */
    }
    /**
     * Sends sdk client report using sendBeacon or fetch as a fallback if available
     *
     * @param url report endpoint
     * @param body report payload
     */
    function sendReport(url, body) {
        var isRealNavigator = Object.prototype.toString.call(global$4 && global$4.navigator) === '[object Navigator]';
        var hasSendBeacon = isRealNavigator && typeof global$4.navigator.sendBeacon === 'function';
        if (hasSendBeacon) {
            // Prevent illegal invocations - https://xgwang.me/posts/you-may-not-know-beacon/#it-may-throw-error%2C-be-sure-to-catch
            var sendBeacon = global$4.navigator.sendBeacon.bind(global$4.navigator);
            return sendBeacon(url, body);
        }
        if (supportsFetch()) {
            var fetch_1 = getNativeFetchImplementation();
            return forget(fetch_1(url, {
                body: body,
                method: 'POST',
                credentials: 'omit',
                keepalive: true,
            }));
        }
    }

    function requestTypeToCategory(ty) {
        var tyStr = ty;
        return tyStr === 'event' ? 'error' : tyStr;
    }
    var global$3 = getGlobalObject();
    /** Base Transport class implementation */
    var BaseTransport = /** @class */ (function () {
        function BaseTransport(options) {
            var _this = this;
            this.options = options;
            /** A simple buffer holding all requests. */
            this._buffer = makePromiseBuffer(30);
            /** Locks transport after receiving rate limits in a response */
            this._rateLimits = {};
            this._outcomes = {};
            this._api = initAPIDetails(options.dsn, options._metadata, options.tunnel);
            // eslint-disable-next-line deprecation/deprecation
            this.url = getStoreEndpointWithUrlEncodedAuth(this._api.dsn);
            if (this.options.sendClientReports && global$3.document) {
                global$3.document.addEventListener('visibilitychange', function () {
                    if (global$3.document.visibilityState === 'hidden') {
                        _this._flushOutcomes();
                    }
                });
            }
        }
        /**
         * @inheritDoc
         */
        BaseTransport.prototype.sendEvent = function (event) {
            return this._sendRequest(eventToSentryRequest(event, this._api), event);
        };
        /**
         * @inheritDoc
         */
        BaseTransport.prototype.sendSession = function (session) {
            return this._sendRequest(sessionToSentryRequest(session, this._api), session);
        };
        /**
         * @inheritDoc
         */
        BaseTransport.prototype.close = function (timeout) {
            return this._buffer.drain(timeout);
        };
        /**
         * @inheritDoc
         */
        BaseTransport.prototype.recordLostEvent = function (reason, category) {
            var _a;
            if (!this.options.sendClientReports) {
                return;
            }
            // We want to track each category (event, transaction, session) separately
            // but still keep the distinction between different type of outcomes.
            // We could use nested maps, but it's much easier to read and type this way.
            // A correct type for map-based implementation if we want to go that route
            // would be `Partial<Record<SentryRequestType, Partial<Record<Outcome, number>>>>`
            var key = requestTypeToCategory(category) + ":" + reason;
            IS_DEBUG_BUILD && logger.log("Adding outcome: " + key);
            this._outcomes[key] = (_a = this._outcomes[key], (_a !== null && _a !== void 0 ? _a : 0)) + 1;
        };
        /**
         * Send outcomes as an envelope
         */
        BaseTransport.prototype._flushOutcomes = function () {
            if (!this.options.sendClientReports) {
                return;
            }
            var outcomes = this._outcomes;
            this._outcomes = {};
            // Nothing to send
            if (!Object.keys(outcomes).length) {
                IS_DEBUG_BUILD && logger.log('No outcomes to flush');
                return;
            }
            IS_DEBUG_BUILD && logger.log("Flushing outcomes:\n" + JSON.stringify(outcomes, null, 2));
            var url = getEnvelopeEndpointWithUrlEncodedAuth(this._api.dsn, this._api.tunnel);
            var discardedEvents = Object.keys(outcomes).map(function (key) {
                var _a = __read(key.split(':'), 2), category = _a[0], reason = _a[1];
                return {
                    reason: reason,
                    category: category,
                    quantity: outcomes[key],
                };
                // TODO: Improve types on discarded_events to get rid of cast
            });
            var envelope = createClientReportEnvelope(discardedEvents, this._api.tunnel && dsnToString(this._api.dsn));
            try {
                sendReport(url, serializeEnvelope(envelope));
            }
            catch (e) {
                IS_DEBUG_BUILD && logger.error(e);
            }
        };
        /**
         * Handle Sentry repsonse for promise-based transports.
         */
        BaseTransport.prototype._handleResponse = function (_a) {
            var requestType = _a.requestType, response = _a.response, headers = _a.headers, resolve = _a.resolve, reject = _a.reject;
            var status = eventStatusFromHttpCode(response.status);
            this._rateLimits = updateRateLimits(this._rateLimits, headers);
            // eslint-disable-next-line deprecation/deprecation
            if (this._isRateLimited(requestType)) {
                IS_DEBUG_BUILD &&
                    // eslint-disable-next-line deprecation/deprecation
                    logger.warn("Too many " + requestType + " requests, backing off until: " + this._disabledUntil(requestType));
            }
            if (status === 'success') {
                resolve({ status: status });
                return;
            }
            reject(response);
        };
        /**
         * Gets the time that given category is disabled until for rate limiting
         *
         * @deprecated Please use `disabledUntil` from @sentry/utils
         */
        BaseTransport.prototype._disabledUntil = function (requestType) {
            var category = requestTypeToCategory(requestType);
            return new Date(disabledUntil(this._rateLimits, category));
        };
        /**
         * Checks if a category is rate limited
         *
         * @deprecated Please use `isRateLimited` from @sentry/utils
         */
        BaseTransport.prototype._isRateLimited = function (requestType) {
            var category = requestTypeToCategory(requestType);
            return isRateLimited(this._rateLimits, category);
        };
        return BaseTransport;
    }());

    /** `fetch` based transport */
    var FetchTransport = /** @class */ (function (_super) {
        __extends(FetchTransport, _super);
        function FetchTransport(options, fetchImpl) {
            if (fetchImpl === void 0) { fetchImpl = getNativeFetchImplementation(); }
            var _this = _super.call(this, options) || this;
            _this._fetch = fetchImpl;
            return _this;
        }
        /**
         * @param sentryRequest Prepared SentryRequest to be delivered
         * @param originalPayload Original payload used to create SentryRequest
         */
        FetchTransport.prototype._sendRequest = function (sentryRequest, originalPayload) {
            var _this = this;
            // eslint-disable-next-line deprecation/deprecation
            if (this._isRateLimited(sentryRequest.type)) {
                this.recordLostEvent('ratelimit_backoff', sentryRequest.type);
                return Promise.reject({
                    event: originalPayload,
                    type: sentryRequest.type,
                    // eslint-disable-next-line deprecation/deprecation
                    reason: "Transport for " + sentryRequest.type + " requests locked till " + this._disabledUntil(sentryRequest.type) + " due to too many requests.",
                    status: 429,
                });
            }
            var options = {
                body: sentryRequest.body,
                method: 'POST',
                // Despite all stars in the sky saying that Edge supports old draft syntax, aka 'never', 'always', 'origin' and 'default'
                // (see https://caniuse.com/#feat=referrer-policy),
                // it doesn't. And it throws an exception instead of ignoring this parameter...
                // REF: https://github.com/getsentry/raven-js/issues/1233
                referrerPolicy: (supportsReferrerPolicy() ? 'origin' : ''),
            };
            if (this.options.fetchParameters !== undefined) {
                Object.assign(options, this.options.fetchParameters);
            }
            if (this.options.headers !== undefined) {
                options.headers = this.options.headers;
            }
            return this._buffer
                .add(function () {
                return new SyncPromise(function (resolve, reject) {
                    void _this._fetch(sentryRequest.url, options)
                        .then(function (response) {
                        var headers = {
                            'x-sentry-rate-limits': response.headers.get('X-Sentry-Rate-Limits'),
                            'retry-after': response.headers.get('Retry-After'),
                        };
                        _this._handleResponse({
                            requestType: sentryRequest.type,
                            response: response,
                            headers: headers,
                            resolve: resolve,
                            reject: reject,
                        });
                    })
                        .catch(reject);
                });
            })
                .then(undefined, function (reason) {
                // It's either buffer rejection or any other xhr/fetch error, which are treated as NetworkError.
                if (reason instanceof SentryError) {
                    _this.recordLostEvent('queue_overflow', sentryRequest.type);
                }
                else {
                    _this.recordLostEvent('network_error', sentryRequest.type);
                }
                throw reason;
            });
        };
        return FetchTransport;
    }(BaseTransport));

    /** `XHR` based transport */
    var XHRTransport = /** @class */ (function (_super) {
        __extends(XHRTransport, _super);
        function XHRTransport() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        /**
         * @param sentryRequest Prepared SentryRequest to be delivered
         * @param originalPayload Original payload used to create SentryRequest
         */
        XHRTransport.prototype._sendRequest = function (sentryRequest, originalPayload) {
            var _this = this;
            // eslint-disable-next-line deprecation/deprecation
            if (this._isRateLimited(sentryRequest.type)) {
                this.recordLostEvent('ratelimit_backoff', sentryRequest.type);
                return Promise.reject({
                    event: originalPayload,
                    type: sentryRequest.type,
                    // eslint-disable-next-line deprecation/deprecation
                    reason: "Transport for " + sentryRequest.type + " requests locked till " + this._disabledUntil(sentryRequest.type) + " due to too many requests.",
                    status: 429,
                });
            }
            return this._buffer
                .add(function () {
                return new SyncPromise(function (resolve, reject) {
                    var request = new XMLHttpRequest();
                    request.onreadystatechange = function () {
                        if (request.readyState === 4) {
                            var headers = {
                                'x-sentry-rate-limits': request.getResponseHeader('X-Sentry-Rate-Limits'),
                                'retry-after': request.getResponseHeader('Retry-After'),
                            };
                            _this._handleResponse({ requestType: sentryRequest.type, response: request, headers: headers, resolve: resolve, reject: reject });
                        }
                    };
                    request.open('POST', sentryRequest.url);
                    for (var header in _this.options.headers) {
                        if (Object.prototype.hasOwnProperty.call(_this.options.headers, header)) {
                            request.setRequestHeader(header, _this.options.headers[header]);
                        }
                    }
                    request.send(sentryRequest.body);
                });
            })
                .then(undefined, function (reason) {
                // It's either buffer rejection or any other xhr/fetch error, which are treated as NetworkError.
                if (reason instanceof SentryError) {
                    _this.recordLostEvent('queue_overflow', sentryRequest.type);
                }
                else {
                    _this.recordLostEvent('network_error', sentryRequest.type);
                }
                throw reason;
            });
        };
        return XHRTransport;
    }(BaseTransport));

    /**
     * Creates a Transport that uses the Fetch API to send events to Sentry.
     */
    function makeNewFetchTransport(options, nativeFetch) {
        if (nativeFetch === void 0) { nativeFetch = getNativeFetchImplementation(); }
        function makeRequest(request) {
            var requestOptions = __assign({ body: request.body, method: 'POST', referrerPolicy: 'origin' }, options.requestOptions);
            return nativeFetch(options.url, requestOptions).then(function (response) {
                return response.text().then(function (body) { return ({
                    body: body,
                    headers: {
                        'x-sentry-rate-limits': response.headers.get('X-Sentry-Rate-Limits'),
                        'retry-after': response.headers.get('Retry-After'),
                    },
                    reason: response.statusText,
                    statusCode: response.status,
                }); });
            });
        }
        return createTransport({ bufferSize: options.bufferSize }, makeRequest);
    }

    /**
     * The DONE ready state for XmlHttpRequest
     *
     * Defining it here as a constant b/c XMLHttpRequest.DONE is not always defined
     * (e.g. during testing, it is `undefined`)
     *
     * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/readyState}
     */
    var XHR_READYSTATE_DONE = 4;
    /**
     * Creates a Transport that uses the XMLHttpRequest API to send events to Sentry.
     */
    function makeNewXHRTransport(options) {
        function makeRequest(request) {
            return new SyncPromise(function (resolve, _reject) {
                var xhr = new XMLHttpRequest();
                xhr.onreadystatechange = function () {
                    if (xhr.readyState === XHR_READYSTATE_DONE) {
                        var response = {
                            body: xhr.response,
                            headers: {
                                'x-sentry-rate-limits': xhr.getResponseHeader('X-Sentry-Rate-Limits'),
                                'retry-after': xhr.getResponseHeader('Retry-After'),
                            },
                            reason: xhr.statusText,
                            statusCode: xhr.status,
                        };
                        resolve(response);
                    }
                };
                xhr.open('POST', options.url);
                for (var header in options.headers) {
                    if (Object.prototype.hasOwnProperty.call(options.headers, header)) {
                        xhr.setRequestHeader(header, options.headers[header]);
                    }
                }
                xhr.send(request.body);
            });
        }
        return createTransport({ bufferSize: options.bufferSize }, makeRequest);
    }

    var index = /*#__PURE__*/Object.freeze({
        __proto__: null,
        BaseTransport: BaseTransport,
        FetchTransport: FetchTransport,
        XHRTransport: XHRTransport,
        makeNewFetchTransport: makeNewFetchTransport,
        makeNewXHRTransport: makeNewXHRTransport
    });

    /**
     * The Sentry Browser SDK Backend.
     * @hidden
     */
    var BrowserBackend = /** @class */ (function (_super) {
        __extends(BrowserBackend, _super);
        function BrowserBackend() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        /**
         * @inheritDoc
         */
        BrowserBackend.prototype.eventFromException = function (exception, hint) {
            return eventFromException(exception, hint, this._options.attachStacktrace);
        };
        /**
         * @inheritDoc
         */
        BrowserBackend.prototype.eventFromMessage = function (message, level, hint) {
            if (level === void 0) { level = exports.Severity.Info; }
            return eventFromMessage(message, level, hint, this._options.attachStacktrace);
        };
        /**
         * @inheritDoc
         */
        BrowserBackend.prototype._setupTransport = function () {
            if (!this._options.dsn) {
                // We return the noop transport here in case there is no Dsn.
                return _super.prototype._setupTransport.call(this);
            }
            var transportOptions = __assign(__assign({}, this._options.transportOptions), { dsn: this._options.dsn, tunnel: this._options.tunnel, sendClientReports: this._options.sendClientReports, _metadata: this._options._metadata });
            var api = initAPIDetails(transportOptions.dsn, transportOptions._metadata, transportOptions.tunnel);
            var url = getEnvelopeEndpointWithUrlEncodedAuth(api.dsn, api.tunnel);
            if (this._options.transport) {
                return new this._options.transport(transportOptions);
            }
            if (supportsFetch()) {
                var requestOptions = __assign({}, transportOptions.fetchParameters);
                this._newTransport = makeNewFetchTransport({ requestOptions: requestOptions, url: url });
                return new FetchTransport(transportOptions);
            }
            this._newTransport = makeNewXHRTransport({
                url: url,
                headers: transportOptions.headers,
            });
            return new XHRTransport(transportOptions);
        };
        return BrowserBackend;
    }(BaseBackend));

    var global$2 = getGlobalObject();
    var ignoreOnError = 0;
    /**
     * @hidden
     */
    function shouldIgnoreOnError() {
        return ignoreOnError > 0;
    }
    /**
     * @hidden
     */
    function ignoreNextOnError() {
        // onerror should trigger before setTimeout
        ignoreOnError += 1;
        setTimeout(function () {
            ignoreOnError -= 1;
        });
    }
    /**
     * Instruments the given function and sends an event to Sentry every time the
     * function throws an exception.
     *
     * @param fn A function to wrap.
     * @returns The wrapped function.
     * @hidden
     */
    function wrap$1(fn, options, before) {
        // for future readers what this does is wrap a function and then create
        // a bi-directional wrapping between them.
        //
        // example: wrapped = wrap(original);
        //  original.__sentry_wrapped__ -> wrapped
        //  wrapped.__sentry_original__ -> original
        if (options === void 0) { options = {}; }
        if (typeof fn !== 'function') {
            return fn;
        }
        try {
            // if we're dealing with a function that was previously wrapped, return
            // the original wrapper.
            var wrapper = fn.__sentry_wrapped__;
            if (wrapper) {
                return wrapper;
            }
            // We don't wanna wrap it twice
            if (getOriginalFunction(fn)) {
                return fn;
            }
        }
        catch (e) {
            // Just accessing custom props in some Selenium environments
            // can cause a "Permission denied" exception (see raven-js#495).
            // Bail on wrapping and return the function as-is (defers to window.onerror).
            return fn;
        }
        /* eslint-disable prefer-rest-params */
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var sentryWrapped = function () {
            var args = Array.prototype.slice.call(arguments);
            try {
                if (before && typeof before === 'function') {
                    before.apply(this, arguments);
                }
                // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-member-access
                var wrappedArguments = args.map(function (arg) { return wrap$1(arg, options); });
                // Attempt to invoke user-land function
                // NOTE: If you are a Sentry user, and you are seeing this stack frame, it
                //       means the sentry.javascript SDK caught an error invoking your application code. This
                //       is expected behavior and NOT indicative of a bug with sentry.javascript.
                return fn.apply(this, wrappedArguments);
            }
            catch (ex) {
                ignoreNextOnError();
                withScope(function (scope) {
                    scope.addEventProcessor(function (event) {
                        if (options.mechanism) {
                            addExceptionTypeValue(event, undefined, undefined);
                            addExceptionMechanism(event, options.mechanism);
                        }
                        event.extra = __assign(__assign({}, event.extra), { arguments: args });
                        return event;
                    });
                    captureException(ex);
                });
                throw ex;
            }
        };
        /* eslint-enable prefer-rest-params */
        // Accessing some objects may throw
        // ref: https://github.com/getsentry/sentry-javascript/issues/1168
        try {
            for (var property in fn) {
                if (Object.prototype.hasOwnProperty.call(fn, property)) {
                    sentryWrapped[property] = fn[property];
                }
            }
        }
        catch (_oO) { } // eslint-disable-line no-empty
        // Signal that this function has been wrapped/filled already
        // for both debugging and to prevent it to being wrapped/filled twice
        markFunctionWrapped(sentryWrapped, fn);
        addNonEnumerableProperty(fn, '__sentry_wrapped__', sentryWrapped);
        // Restore original function name (not all browsers allow that)
        try {
            var descriptor = Object.getOwnPropertyDescriptor(sentryWrapped, 'name');
            if (descriptor.configurable) {
                Object.defineProperty(sentryWrapped, 'name', {
                    get: function () {
                        return fn.name;
                    },
                });
            }
            // eslint-disable-next-line no-empty
        }
        catch (_oO) { }
        return sentryWrapped;
    }
    /**
     * Injects the Report Dialog script
     * @hidden
     */
    function injectReportDialog(options) {
        if (options === void 0) { options = {}; }
        if (!global$2.document) {
            return;
        }
        if (!options.eventId) {
            IS_DEBUG_BUILD && logger.error('Missing eventId option in showReportDialog call');
            return;
        }
        if (!options.dsn) {
            IS_DEBUG_BUILD && logger.error('Missing dsn option in showReportDialog call');
            return;
        }
        var script = global$2.document.createElement('script');
        script.async = true;
        script.src = getReportDialogEndpoint(options.dsn, options);
        if (options.onLoad) {
            // eslint-disable-next-line @typescript-eslint/unbound-method
            script.onload = options.onLoad;
        }
        var injectionPoint = global$2.document.head || global$2.document.body;
        if (injectionPoint) {
            injectionPoint.appendChild(script);
        }
    }

    /** Global handlers */
    var GlobalHandlers = /** @class */ (function () {
        /** JSDoc */
        function GlobalHandlers(options) {
            /**
             * @inheritDoc
             */
            this.name = GlobalHandlers.id;
            /**
             * Stores references functions to installing handlers. Will set to undefined
             * after they have been run so that they are not used twice.
             */
            this._installFunc = {
                onerror: _installGlobalOnErrorHandler,
                onunhandledrejection: _installGlobalOnUnhandledRejectionHandler,
            };
            this._options = __assign({ onerror: true, onunhandledrejection: true }, options);
        }
        /**
         * @inheritDoc
         */
        GlobalHandlers.prototype.setupOnce = function () {
            Error.stackTraceLimit = 50;
            var options = this._options;
            // We can disable guard-for-in as we construct the options object above + do checks against
            // `this._installFunc` for the property.
            // eslint-disable-next-line guard-for-in
            for (var key in options) {
                var installFunc = this._installFunc[key];
                if (installFunc && options[key]) {
                    globalHandlerLog(key);
                    installFunc();
                    this._installFunc[key] = undefined;
                }
            }
        };
        /**
         * @inheritDoc
         */
        GlobalHandlers.id = 'GlobalHandlers';
        return GlobalHandlers;
    }());
    /** JSDoc */
    function _installGlobalOnErrorHandler() {
        addInstrumentationHandler('error', 
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        function (data) {
            var _a = __read(getHubAndAttachStacktrace(), 2), hub = _a[0], attachStacktrace = _a[1];
            if (!hub.getIntegration(GlobalHandlers)) {
                return;
            }
            var msg = data.msg, url = data.url, line = data.line, column = data.column, error = data.error;
            if (shouldIgnoreOnError() || (error && error.__sentry_own_request__)) {
                return;
            }
            var event = error === undefined && isString(msg)
                ? _eventFromIncompleteOnError(msg, url, line, column)
                : _enhanceEventWithInitialFrame(eventFromUnknownInput(error || msg, undefined, attachStacktrace, false), url, line, column);
            event.level = exports.Severity.Error;
            addMechanismAndCapture(hub, error, event, 'onerror');
        });
    }
    /** JSDoc */
    function _installGlobalOnUnhandledRejectionHandler() {
        addInstrumentationHandler('unhandledrejection', 
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        function (e) {
            var _a = __read(getHubAndAttachStacktrace(), 2), hub = _a[0], attachStacktrace = _a[1];
            if (!hub.getIntegration(GlobalHandlers)) {
                return;
            }
            var error = e;
            // dig the object of the rejection out of known event types
            try {
                // PromiseRejectionEvents store the object of the rejection under 'reason'
                // see https://developer.mozilla.org/en-US/docs/Web/API/PromiseRejectionEvent
                if ('reason' in e) {
                    error = e.reason;
                }
                // something, somewhere, (likely a browser extension) effectively casts PromiseRejectionEvents
                // to CustomEvents, moving the `promise` and `reason` attributes of the PRE into
                // the CustomEvent's `detail` attribute, since they're not part of CustomEvent's spec
                // see https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent and
                // https://github.com/getsentry/sentry-javascript/issues/2380
                else if ('detail' in e && 'reason' in e.detail) {
                    error = e.detail.reason;
                }
            }
            catch (_oO) {
                // no-empty
            }
            if (shouldIgnoreOnError() || (error && error.__sentry_own_request__)) {
                return true;
            }
            var event = isPrimitive(error)
                ? _eventFromRejectionWithPrimitive(error)
                : eventFromUnknownInput(error, undefined, attachStacktrace, true);
            event.level = exports.Severity.Error;
            addMechanismAndCapture(hub, error, event, 'onunhandledrejection');
            return;
        });
    }
    /**
     * Create an event from a promise rejection where the `reason` is a primitive.
     *
     * @param reason: The `reason` property of the promise rejection
     * @returns An Event object with an appropriate `exception` value
     */
    function _eventFromRejectionWithPrimitive(reason) {
        return {
            exception: {
                values: [
                    {
                        type: 'UnhandledRejection',
                        // String() is needed because the Primitive type includes symbols (which can't be automatically stringified)
                        value: "Non-Error promise rejection captured with value: " + String(reason),
                    },
                ],
            },
        };
    }
    /**
     * This function creates a stack from an old, error-less onerror handler.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _eventFromIncompleteOnError(msg, url, line, column) {
        var ERROR_TYPES_RE = /^(?:[Uu]ncaught (?:exception: )?)?(?:((?:Eval|Internal|Range|Reference|Syntax|Type|URI|)Error): )?(.*)$/i;
        // If 'message' is ErrorEvent, get real message from inside
        var message = isErrorEvent(msg) ? msg.message : msg;
        var name = 'Error';
        var groups = message.match(ERROR_TYPES_RE);
        if (groups) {
            name = groups[1];
            message = groups[2];
        }
        var event = {
            exception: {
                values: [
                    {
                        type: name,
                        value: message,
                    },
                ],
            },
        };
        return _enhanceEventWithInitialFrame(event, url, line, column);
    }
    /** JSDoc */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _enhanceEventWithInitialFrame(event, url, line, column) {
        // event.exception
        var e = (event.exception = event.exception || {});
        // event.exception.values
        var ev = (e.values = e.values || []);
        // event.exception.values[0]
        var ev0 = (ev[0] = ev[0] || {});
        // event.exception.values[0].stacktrace
        var ev0s = (ev0.stacktrace = ev0.stacktrace || {});
        // event.exception.values[0].stacktrace.frames
        var ev0sf = (ev0s.frames = ev0s.frames || []);
        var colno = isNaN(parseInt(column, 10)) ? undefined : column;
        var lineno = isNaN(parseInt(line, 10)) ? undefined : line;
        var filename = isString(url) && url.length > 0 ? url : getLocationHref();
        // event.exception.values[0].stacktrace.frames
        if (ev0sf.length === 0) {
            ev0sf.push({
                colno: colno,
                filename: filename,
                function: '?',
                in_app: true,
                lineno: lineno,
            });
        }
        return event;
    }
    function globalHandlerLog(type) {
        IS_DEBUG_BUILD && logger.log("Global Handler attached: " + type);
    }
    function addMechanismAndCapture(hub, error, event, type) {
        addExceptionMechanism(event, {
            handled: false,
            type: type,
        });
        hub.captureEvent(event, {
            originalException: error,
        });
    }
    function getHubAndAttachStacktrace() {
        var hub = getCurrentHub();
        var client = hub.getClient();
        var attachStacktrace = client && client.getOptions().attachStacktrace;
        return [hub, attachStacktrace];
    }

    var DEFAULT_EVENT_TARGET = [
        'EventTarget',
        'Window',
        'Node',
        'ApplicationCache',
        'AudioTrackList',
        'ChannelMergerNode',
        'CryptoOperation',
        'EventSource',
        'FileReader',
        'HTMLUnknownElement',
        'IDBDatabase',
        'IDBRequest',
        'IDBTransaction',
        'KeyOperation',
        'MediaController',
        'MessagePort',
        'ModalWindow',
        'Notification',
        'SVGElementInstance',
        'Screen',
        'TextTrack',
        'TextTrackCue',
        'TextTrackList',
        'WebSocket',
        'WebSocketWorker',
        'Worker',
        'XMLHttpRequest',
        'XMLHttpRequestEventTarget',
        'XMLHttpRequestUpload',
    ];
    /** Wrap timer functions and event targets to catch errors and provide better meta data */
    var TryCatch = /** @class */ (function () {
        /**
         * @inheritDoc
         */
        function TryCatch(options) {
            /**
             * @inheritDoc
             */
            this.name = TryCatch.id;
            this._options = __assign({ XMLHttpRequest: true, eventTarget: true, requestAnimationFrame: true, setInterval: true, setTimeout: true }, options);
        }
        /**
         * Wrap timer functions and event targets to catch errors
         * and provide better metadata.
         */
        TryCatch.prototype.setupOnce = function () {
            var global = getGlobalObject();
            if (this._options.setTimeout) {
                fill(global, 'setTimeout', _wrapTimeFunction);
            }
            if (this._options.setInterval) {
                fill(global, 'setInterval', _wrapTimeFunction);
            }
            if (this._options.requestAnimationFrame) {
                fill(global, 'requestAnimationFrame', _wrapRAF);
            }
            if (this._options.XMLHttpRequest && 'XMLHttpRequest' in global) {
                fill(XMLHttpRequest.prototype, 'send', _wrapXHR);
            }
            var eventTargetOption = this._options.eventTarget;
            if (eventTargetOption) {
                var eventTarget = Array.isArray(eventTargetOption) ? eventTargetOption : DEFAULT_EVENT_TARGET;
                eventTarget.forEach(_wrapEventTarget);
            }
        };
        /**
         * @inheritDoc
         */
        TryCatch.id = 'TryCatch';
        return TryCatch;
    }());
    /** JSDoc */
    function _wrapTimeFunction(original) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            var originalCallback = args[0];
            args[0] = wrap$1(originalCallback, {
                mechanism: {
                    data: { function: getFunctionName(original) },
                    handled: true,
                    type: 'instrument',
                },
            });
            return original.apply(this, args);
        };
    }
    /** JSDoc */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _wrapRAF(original) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return function (callback) {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            return original.apply(this, [
                wrap$1(callback, {
                    mechanism: {
                        data: {
                            function: 'requestAnimationFrame',
                            handler: getFunctionName(original),
                        },
                        handled: true,
                        type: 'instrument',
                    },
                }),
            ]);
        };
    }
    /** JSDoc */
    function _wrapXHR(originalSend) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            // eslint-disable-next-line @typescript-eslint/no-this-alias
            var xhr = this;
            var xmlHttpRequestProps = ['onload', 'onerror', 'onprogress', 'onreadystatechange'];
            xmlHttpRequestProps.forEach(function (prop) {
                if (prop in xhr && typeof xhr[prop] === 'function') {
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    fill(xhr, prop, function (original) {
                        var wrapOptions = {
                            mechanism: {
                                data: {
                                    function: prop,
                                    handler: getFunctionName(original),
                                },
                                handled: true,
                                type: 'instrument',
                            },
                        };
                        // If Instrument integration has been called before TryCatch, get the name of original function
                        var originalFunction = getOriginalFunction(original);
                        if (originalFunction) {
                            wrapOptions.mechanism.data.handler = getFunctionName(originalFunction);
                        }
                        // Otherwise wrap directly
                        return wrap$1(original, wrapOptions);
                    });
                }
            });
            return originalSend.apply(this, args);
        };
    }
    /** JSDoc */
    function _wrapEventTarget(target) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var global = getGlobalObject();
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        var proto = global[target] && global[target].prototype;
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, no-prototype-builtins
        if (!proto || !proto.hasOwnProperty || !proto.hasOwnProperty('addEventListener')) {
            return;
        }
        fill(proto, 'addEventListener', function (original) {
            return function (eventName, fn, options) {
                try {
                    if (typeof fn.handleEvent === 'function') {
                        fn.handleEvent = wrap$1(fn.handleEvent.bind(fn), {
                            mechanism: {
                                data: {
                                    function: 'handleEvent',
                                    handler: getFunctionName(fn),
                                    target: target,
                                },
                                handled: true,
                                type: 'instrument',
                            },
                        });
                    }
                }
                catch (err) {
                    // can sometimes get 'Permission denied to access property "handle Event'
                }
                return original.apply(this, [
                    eventName,
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    wrap$1(fn, {
                        mechanism: {
                            data: {
                                function: 'addEventListener',
                                handler: getFunctionName(fn),
                                target: target,
                            },
                            handled: true,
                            type: 'instrument',
                        },
                    }),
                    options,
                ]);
            };
        });
        fill(proto, 'removeEventListener', function (originalRemoveEventListener) {
            return function (eventName, fn, options) {
                /**
                 * There are 2 possible scenarios here:
                 *
                 * 1. Someone passes a callback, which was attached prior to Sentry initialization, or by using unmodified
                 * method, eg. `document.addEventListener.call(el, name, handler). In this case, we treat this function
                 * as a pass-through, and call original `removeEventListener` with it.
                 *
                 * 2. Someone passes a callback, which was attached after Sentry was initialized, which means that it was using
                 * our wrapped version of `addEventListener`, which internally calls `wrap` helper.
                 * This helper "wraps" whole callback inside a try/catch statement, and attached appropriate metadata to it,
                 * in order for us to make a distinction between wrapped/non-wrapped functions possible.
                 * If a function was wrapped, it has additional property of `__sentry_wrapped__`, holding the handler.
                 *
                 * When someone adds a handler prior to initialization, and then do it again, but after,
                 * then we have to detach both of them. Otherwise, if we'd detach only wrapped one, it'd be impossible
                 * to get rid of the initial handler and it'd stick there forever.
                 */
                var wrappedEventHandler = fn;
                try {
                    var originalEventHandler = wrappedEventHandler && wrappedEventHandler.__sentry_wrapped__;
                    if (originalEventHandler) {
                        originalRemoveEventListener.call(this, eventName, originalEventHandler, options);
                    }
                }
                catch (e) {
                    // ignore, accessing __sentry_wrapped__ will throw in some Selenium environments
                }
                return originalRemoveEventListener.call(this, eventName, wrappedEventHandler, options);
            };
        });
    }

    /**
     * Default Breadcrumbs instrumentations
     * TODO: Deprecated - with v6, this will be renamed to `Instrument`
     */
    var Breadcrumbs = /** @class */ (function () {
        /**
         * @inheritDoc
         */
        function Breadcrumbs(options) {
            /**
             * @inheritDoc
             */
            this.name = Breadcrumbs.id;
            this._options = __assign({ console: true, dom: true, fetch: true, history: true, sentry: true, xhr: true }, options);
        }
        /**
         * Create a breadcrumb of `sentry` from the events themselves
         */
        Breadcrumbs.prototype.addSentryBreadcrumb = function (event) {
            if (!this._options.sentry) {
                return;
            }
            getCurrentHub().addBreadcrumb({
                category: "sentry." + (event.type === 'transaction' ? 'transaction' : 'event'),
                event_id: event.event_id,
                level: event.level,
                message: getEventDescription(event),
            }, {
                event: event,
            });
        };
        /**
         * Instrument browser built-ins w/ breadcrumb capturing
         *  - Console API
         *  - DOM API (click/typing)
         *  - XMLHttpRequest API
         *  - Fetch API
         *  - History API
         */
        Breadcrumbs.prototype.setupOnce = function () {
            if (this._options.console) {
                addInstrumentationHandler('console', _consoleBreadcrumb);
            }
            if (this._options.dom) {
                addInstrumentationHandler('dom', _domBreadcrumb(this._options.dom));
            }
            if (this._options.xhr) {
                addInstrumentationHandler('xhr', _xhrBreadcrumb);
            }
            if (this._options.fetch) {
                addInstrumentationHandler('fetch', _fetchBreadcrumb);
            }
            if (this._options.history) {
                addInstrumentationHandler('history', _historyBreadcrumb);
            }
        };
        /**
         * @inheritDoc
         */
        Breadcrumbs.id = 'Breadcrumbs';
        return Breadcrumbs;
    }());
    /**
     * A HOC that creaes a function that creates breadcrumbs from DOM API calls.
     * This is a HOC so that we get access to dom options in the closure.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _domBreadcrumb(dom) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        function _innerDomBreadcrumb(handlerData) {
            var target;
            var keyAttrs = typeof dom === 'object' ? dom.serializeAttribute : undefined;
            if (typeof keyAttrs === 'string') {
                keyAttrs = [keyAttrs];
            }
            // Accessing event.target can throw (see getsentry/raven-js#838, #768)
            try {
                target = handlerData.event.target
                    ? htmlTreeAsString(handlerData.event.target, keyAttrs)
                    : htmlTreeAsString(handlerData.event, keyAttrs);
            }
            catch (e) {
                target = '<unknown>';
            }
            if (target.length === 0) {
                return;
            }
            getCurrentHub().addBreadcrumb({
                category: "ui." + handlerData.name,
                message: target,
            }, {
                event: handlerData.event,
                name: handlerData.name,
                global: handlerData.global,
            });
        }
        return _innerDomBreadcrumb;
    }
    /**
     * Creates breadcrumbs from console API calls
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _consoleBreadcrumb(handlerData) {
        var breadcrumb = {
            category: 'console',
            data: {
                arguments: handlerData.args,
                logger: 'console',
            },
            level: severityFromString(handlerData.level),
            message: safeJoin(handlerData.args, ' '),
        };
        if (handlerData.level === 'assert') {
            if (handlerData.args[0] === false) {
                breadcrumb.message = "Assertion failed: " + (safeJoin(handlerData.args.slice(1), ' ') || 'console.assert');
                breadcrumb.data.arguments = handlerData.args.slice(1);
            }
            else {
                // Don't capture a breadcrumb for passed assertions
                return;
            }
        }
        getCurrentHub().addBreadcrumb(breadcrumb, {
            input: handlerData.args,
            level: handlerData.level,
        });
    }
    /**
     * Creates breadcrumbs from XHR API calls
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _xhrBreadcrumb(handlerData) {
        if (handlerData.endTimestamp) {
            // We only capture complete, non-sentry requests
            if (handlerData.xhr.__sentry_own_request__) {
                return;
            }
            var _a = handlerData.xhr.__sentry_xhr__ || {}, method = _a.method, url = _a.url, status_code = _a.status_code, body = _a.body;
            getCurrentHub().addBreadcrumb({
                category: 'xhr',
                data: {
                    method: method,
                    url: url,
                    status_code: status_code,
                },
                type: 'http',
            }, {
                xhr: handlerData.xhr,
                input: body,
            });
            return;
        }
    }
    /**
     * Creates breadcrumbs from fetch API calls
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _fetchBreadcrumb(handlerData) {
        // We only capture complete fetch requests
        if (!handlerData.endTimestamp) {
            return;
        }
        if (handlerData.fetchData.url.match(/sentry_key/) && handlerData.fetchData.method === 'POST') {
            // We will not create breadcrumbs for fetch requests that contain `sentry_key` (internal sentry requests)
            return;
        }
        if (handlerData.error) {
            getCurrentHub().addBreadcrumb({
                category: 'fetch',
                data: handlerData.fetchData,
                level: exports.Severity.Error,
                type: 'http',
            }, {
                data: handlerData.error,
                input: handlerData.args,
            });
        }
        else {
            getCurrentHub().addBreadcrumb({
                category: 'fetch',
                data: __assign(__assign({}, handlerData.fetchData), { status_code: handlerData.response.status }),
                type: 'http',
            }, {
                input: handlerData.args,
                response: handlerData.response,
            });
        }
    }
    /**
     * Creates breadcrumbs from history API calls
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function _historyBreadcrumb(handlerData) {
        var global = getGlobalObject();
        var from = handlerData.from;
        var to = handlerData.to;
        var parsedLoc = parseUrl(global.location.href);
        var parsedFrom = parseUrl(from);
        var parsedTo = parseUrl(to);
        // Initial pushState doesn't provide `from` information
        if (!parsedFrom.path) {
            parsedFrom = parsedLoc;
        }
        // Use only the path component of the URL if the URL matches the current
        // document (almost all the time when using pushState)
        if (parsedLoc.protocol === parsedTo.protocol && parsedLoc.host === parsedTo.host) {
            to = parsedTo.relative;
        }
        if (parsedLoc.protocol === parsedFrom.protocol && parsedLoc.host === parsedFrom.host) {
            from = parsedFrom.relative;
        }
        getCurrentHub().addBreadcrumb({
            category: 'navigation',
            data: {
                from: from,
                to: to,
            },
        });
    }

    var DEFAULT_KEY = 'cause';
    var DEFAULT_LIMIT = 5;
    /** Adds SDK info to an event. */
    var LinkedErrors = /** @class */ (function () {
        /**
         * @inheritDoc
         */
        function LinkedErrors(options) {
            if (options === void 0) { options = {}; }
            /**
             * @inheritDoc
             */
            this.name = LinkedErrors.id;
            this._key = options.key || DEFAULT_KEY;
            this._limit = options.limit || DEFAULT_LIMIT;
        }
        /**
         * @inheritDoc
         */
        LinkedErrors.prototype.setupOnce = function () {
            addGlobalEventProcessor(function (event, hint) {
                var self = getCurrentHub().getIntegration(LinkedErrors);
                return self ? _handler(self._key, self._limit, event, hint) : event;
            });
        };
        /**
         * @inheritDoc
         */
        LinkedErrors.id = 'LinkedErrors';
        return LinkedErrors;
    }());
    /**
     * @inheritDoc
     */
    function _handler(key, limit, event, hint) {
        if (!event.exception || !event.exception.values || !hint || !isInstanceOf(hint.originalException, Error)) {
            return event;
        }
        var linkedErrors = _walkErrorTree(limit, hint.originalException, key);
        event.exception.values = __spread(linkedErrors, event.exception.values);
        return event;
    }
    /**
     * JSDOC
     */
    function _walkErrorTree(limit, error, key, stack) {
        if (stack === void 0) { stack = []; }
        if (!isInstanceOf(error[key], Error) || stack.length + 1 >= limit) {
            return stack;
        }
        var exception = exceptionFromError(error[key]);
        return _walkErrorTree(limit, error[key], key, __spread([exception], stack));
    }

    var global$1 = getGlobalObject();
    /** UserAgent */
    var UserAgent = /** @class */ (function () {
        function UserAgent() {
            /**
             * @inheritDoc
             */
            this.name = UserAgent.id;
        }
        /**
         * @inheritDoc
         */
        UserAgent.prototype.setupOnce = function () {
            addGlobalEventProcessor(function (event) {
                if (getCurrentHub().getIntegration(UserAgent)) {
                    // if none of the information we want exists, don't bother
                    if (!global$1.navigator && !global$1.location && !global$1.document) {
                        return event;
                    }
                    // grab as much info as exists and add it to the event
                    var url = (event.request && event.request.url) || (global$1.location && global$1.location.href);
                    var referrer = (global$1.document || {}).referrer;
                    var userAgent = (global$1.navigator || {}).userAgent;
                    var headers = __assign(__assign(__assign({}, (event.request && event.request.headers)), (referrer && { Referer: referrer })), (userAgent && { 'User-Agent': userAgent }));
                    var request = __assign(__assign({}, (url && { url: url })), { headers: headers });
                    return __assign(__assign({}, event), { request: request });
                }
                return event;
            });
        };
        /**
         * @inheritDoc
         */
        UserAgent.id = 'UserAgent';
        return UserAgent;
    }());

    /** Deduplication filter */
    var Dedupe = /** @class */ (function () {
        function Dedupe() {
            /**
             * @inheritDoc
             */
            this.name = Dedupe.id;
        }
        /**
         * @inheritDoc
         */
        Dedupe.prototype.setupOnce = function (addGlobalEventProcessor, getCurrentHub) {
            addGlobalEventProcessor(function (currentEvent) {
                var self = getCurrentHub().getIntegration(Dedupe);
                if (self) {
                    // Juuust in case something goes wrong
                    try {
                        if (_shouldDropEvent(currentEvent, self._previousEvent)) {
                            IS_DEBUG_BUILD && logger.warn('Event dropped due to being a duplicate of previously captured event.');
                            return null;
                        }
                    }
                    catch (_oO) {
                        return (self._previousEvent = currentEvent);
                    }
                    return (self._previousEvent = currentEvent);
                }
                return currentEvent;
            });
        };
        /**
         * @inheritDoc
         */
        Dedupe.id = 'Dedupe';
        return Dedupe;
    }());
    /** JSDoc */
    function _shouldDropEvent(currentEvent, previousEvent) {
        if (!previousEvent) {
            return false;
        }
        if (_isSameMessageEvent(currentEvent, previousEvent)) {
            return true;
        }
        if (_isSameExceptionEvent(currentEvent, previousEvent)) {
            return true;
        }
        return false;
    }
    /** JSDoc */
    function _isSameMessageEvent(currentEvent, previousEvent) {
        var currentMessage = currentEvent.message;
        var previousMessage = previousEvent.message;
        // If neither event has a message property, they were both exceptions, so bail out
        if (!currentMessage && !previousMessage) {
            return false;
        }
        // If only one event has a stacktrace, but not the other one, they are not the same
        if ((currentMessage && !previousMessage) || (!currentMessage && previousMessage)) {
            return false;
        }
        if (currentMessage !== previousMessage) {
            return false;
        }
        if (!_isSameFingerprint(currentEvent, previousEvent)) {
            return false;
        }
        if (!_isSameStacktrace(currentEvent, previousEvent)) {
            return false;
        }
        return true;
    }
    /** JSDoc */
    function _isSameExceptionEvent(currentEvent, previousEvent) {
        var previousException = _getExceptionFromEvent(previousEvent);
        var currentException = _getExceptionFromEvent(currentEvent);
        if (!previousException || !currentException) {
            return false;
        }
        if (previousException.type !== currentException.type || previousException.value !== currentException.value) {
            return false;
        }
        if (!_isSameFingerprint(currentEvent, previousEvent)) {
            return false;
        }
        if (!_isSameStacktrace(currentEvent, previousEvent)) {
            return false;
        }
        return true;
    }
    /** JSDoc */
    function _isSameStacktrace(currentEvent, previousEvent) {
        var currentFrames = _getFramesFromEvent(currentEvent);
        var previousFrames = _getFramesFromEvent(previousEvent);
        // If neither event has a stacktrace, they are assumed to be the same
        if (!currentFrames && !previousFrames) {
            return true;
        }
        // If only one event has a stacktrace, but not the other one, they are not the same
        if ((currentFrames && !previousFrames) || (!currentFrames && previousFrames)) {
            return false;
        }
        currentFrames = currentFrames;
        previousFrames = previousFrames;
        // If number of frames differ, they are not the same
        if (previousFrames.length !== currentFrames.length) {
            return false;
        }
        // Otherwise, compare the two
        for (var i = 0; i < previousFrames.length; i++) {
            var frameA = previousFrames[i];
            var frameB = currentFrames[i];
            if (frameA.filename !== frameB.filename ||
                frameA.lineno !== frameB.lineno ||
                frameA.colno !== frameB.colno ||
                frameA.function !== frameB.function) {
                return false;
            }
        }
        return true;
    }
    /** JSDoc */
    function _isSameFingerprint(currentEvent, previousEvent) {
        var currentFingerprint = currentEvent.fingerprint;
        var previousFingerprint = previousEvent.fingerprint;
        // If neither event has a fingerprint, they are assumed to be the same
        if (!currentFingerprint && !previousFingerprint) {
            return true;
        }
        // If only one event has a fingerprint, but not the other one, they are not the same
        if ((currentFingerprint && !previousFingerprint) || (!currentFingerprint && previousFingerprint)) {
            return false;
        }
        currentFingerprint = currentFingerprint;
        previousFingerprint = previousFingerprint;
        // Otherwise, compare the two
        try {
            return !!(currentFingerprint.join('') === previousFingerprint.join(''));
        }
        catch (_oO) {
            return false;
        }
    }
    /** JSDoc */
    function _getExceptionFromEvent(event) {
        return event.exception && event.exception.values && event.exception.values[0];
    }
    /** JSDoc */
    function _getFramesFromEvent(event) {
        var exception = event.exception;
        if (exception) {
            try {
                // @ts-ignore Object could be undefined
                return exception.values[0].stacktrace.frames;
            }
            catch (_oO) {
                return undefined;
            }
        }
        else if (event.stacktrace) {
            return event.stacktrace.frames;
        }
        return undefined;
    }

    var BrowserIntegrations = /*#__PURE__*/Object.freeze({
        __proto__: null,
        GlobalHandlers: GlobalHandlers,
        TryCatch: TryCatch,
        Breadcrumbs: Breadcrumbs,
        LinkedErrors: LinkedErrors,
        UserAgent: UserAgent,
        Dedupe: Dedupe
    });

    /**
     * The Sentry Browser SDK Client.
     *
     * @see BrowserOptions for documentation on configuration options.
     * @see SentryClient for usage documentation.
     */
    var BrowserClient = /** @class */ (function (_super) {
        __extends(BrowserClient, _super);
        /**
         * Creates a new Browser SDK instance.
         *
         * @param options Configuration options for this SDK.
         */
        function BrowserClient(options) {
            if (options === void 0) { options = {}; }
            var _this = this;
            options._metadata = options._metadata || {};
            options._metadata.sdk = options._metadata.sdk || {
                name: 'sentry.javascript.browser',
                packages: [
                    {
                        name: 'npm:@sentry/browser',
                        version: SDK_VERSION,
                    },
                ],
                version: SDK_VERSION,
            };
            _this = _super.call(this, BrowserBackend, options) || this;
            return _this;
        }
        /**
         * Show a report dialog to the user to send feedback to a specific event.
         *
         * @param options Set individual options for the dialog
         */
        BrowserClient.prototype.showReportDialog = function (options) {
            if (options === void 0) { options = {}; }
            // doesn't work without a document (React Native)
            var document = getGlobalObject().document;
            if (!document) {
                return;
            }
            if (!this._isEnabled()) {
                IS_DEBUG_BUILD && logger.error('Trying to call showReportDialog with Sentry Client disabled');
                return;
            }
            injectReportDialog(__assign(__assign({}, options), { dsn: options.dsn || this.getDsn() }));
        };
        /**
         * @inheritDoc
         */
        BrowserClient.prototype._prepareEvent = function (event, scope, hint) {
            event.platform = event.platform || 'javascript';
            return _super.prototype._prepareEvent.call(this, event, scope, hint);
        };
        /**
         * @inheritDoc
         */
        BrowserClient.prototype._sendEvent = function (event) {
            var integration = this.getIntegration(Breadcrumbs);
            if (integration) {
                integration.addSentryBreadcrumb(event);
            }
            _super.prototype._sendEvent.call(this, event);
        };
        return BrowserClient;
    }(BaseClient));

    var defaultIntegrations = [
        new InboundFilters(),
        new FunctionToString(),
        new TryCatch(),
        new Breadcrumbs(),
        new GlobalHandlers(),
        new LinkedErrors(),
        new Dedupe(),
        new UserAgent(),
    ];
    /**
     * The Sentry Browser SDK Client.
     *
     * To use this SDK, call the {@link init} function as early as possible when
     * loading the web page. To set context information or send manual events, use
     * the provided methods.
     *
     * @example
     *
     * ```
     *
     * import { init } from '@sentry/browser';
     *
     * init({
     *   dsn: '__DSN__',
     *   // ...
     * });
     * ```
     *
     * @example
     * ```
     *
     * import { configureScope } from '@sentry/browser';
     * configureScope((scope: Scope) => {
     *   scope.setExtra({ battery: 0.7 });
     *   scope.setTag({ user_mode: 'admin' });
     *   scope.setUser({ id: '4711' });
     * });
     * ```
     *
     * @example
     * ```
     *
     * import { addBreadcrumb } from '@sentry/browser';
     * addBreadcrumb({
     *   message: 'My Breadcrumb',
     *   // ...
     * });
     * ```
     *
     * @example
     *
     * ```
     *
     * import * as Sentry from '@sentry/browser';
     * Sentry.captureMessage('Hello, world!');
     * Sentry.captureException(new Error('Good bye'));
     * Sentry.captureEvent({
     *   message: 'Manual',
     *   stacktrace: [
     *     // ...
     *   ],
     * });
     * ```
     *
     * @see {@link BrowserOptions} for documentation on configuration options.
     */
    function init(options) {
        if (options === void 0) { options = {}; }
        if (options.defaultIntegrations === undefined) {
            options.defaultIntegrations = defaultIntegrations;
        }
        if (options.release === undefined) {
            var window_1 = getGlobalObject();
            // This supports the variable that sentry-webpack-plugin injects
            if (window_1.SENTRY_RELEASE && window_1.SENTRY_RELEASE.id) {
                options.release = window_1.SENTRY_RELEASE.id;
            }
        }
        if (options.autoSessionTracking === undefined) {
            options.autoSessionTracking = true;
        }
        if (options.sendClientReports === undefined) {
            options.sendClientReports = true;
        }
        initAndBind(BrowserClient, options);
        if (options.autoSessionTracking) {
            startSessionTracking();
        }
    }
    /**
     * Present the user with a report dialog.
     *
     * @param options Everything is optional, we try to fetch all info need from the global scope.
     */
    function showReportDialog(options) {
        if (options === void 0) { options = {}; }
        var hub = getCurrentHub();
        var scope = hub.getScope();
        if (scope) {
            options.user = __assign(__assign({}, scope.getUser()), options.user);
        }
        if (!options.eventId) {
            options.eventId = hub.lastEventId();
        }
        var client = hub.getClient();
        if (client) {
            client.showReportDialog(options);
        }
    }
    /**
     * This is the getter for lastEventId.
     *
     * @returns The last event id of a captured event.
     */
    function lastEventId() {
        return getCurrentHub().lastEventId();
    }
    /**
     * This function is here to be API compatible with the loader.
     * @hidden
     */
    function forceLoad() {
        // Noop
    }
    /**
     * This function is here to be API compatible with the loader.
     * @hidden
     */
    function onLoad(callback) {
        callback();
    }
    /**
     * Call `flush()` on the current client, if there is one. See {@link Client.flush}.
     *
     * @param timeout Maximum time in ms the client should wait to flush its event queue. Omitting this parameter will cause
     * the client to wait until all events are sent before resolving the promise.
     * @returns A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
     * doesn't (or if there's no client defined).
     */
    function flush(timeout) {
        var client = getCurrentHub().getClient();
        if (client) {
            return client.flush(timeout);
        }
        IS_DEBUG_BUILD && logger.warn('Cannot flush events. No client defined.');
        return resolvedSyncPromise(false);
    }
    /**
     * Call `close()` on the current client, if there is one. See {@link Client.close}.
     *
     * @param timeout Maximum time in ms the client should wait to flush its event queue before shutting down. Omitting this
     * parameter will cause the client to wait until all events are sent before disabling itself.
     * @returns A promise which resolves to `true` if the queue successfully drains before the timeout, or `false` if it
     * doesn't (or if there's no client defined).
     */
    function close(timeout) {
        var client = getCurrentHub().getClient();
        if (client) {
            return client.close(timeout);
        }
        IS_DEBUG_BUILD && logger.warn('Cannot flush events and disable SDK. No client defined.');
        return resolvedSyncPromise(false);
    }
    /**
     * Wrap code within a try/catch block so the SDK is able to capture errors.
     *
     * @param fn A function to wrap.
     *
     * @returns The result of wrapped function call.
     */
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    function wrap(fn) {
        return wrap$1(fn)();
    }
    function startSessionOnHub(hub) {
        hub.startSession({ ignoreDuration: true });
        hub.captureSession();
    }
    /**
     * Enable automatic Session Tracking for the initial page load.
     */
    function startSessionTracking() {
        var window = getGlobalObject();
        var document = window.document;
        if (typeof document === 'undefined') {
            IS_DEBUG_BUILD && logger.warn('Session tracking in non-browser environment with @sentry/browser is not supported.');
            return;
        }
        var hub = getCurrentHub();
        // The only way for this to be false is for there to be a version mismatch between @sentry/browser (>= 6.0.0) and
        // @sentry/hub (< 5.27.0). In the simple case, there won't ever be such a mismatch, because the two packages are
        // pinned at the same version in package.json, but there are edge cases where it's possible. See
        // https://github.com/getsentry/sentry-javascript/issues/3207 and
        // https://github.com/getsentry/sentry-javascript/issues/3234 and
        // https://github.com/getsentry/sentry-javascript/issues/3278.
        if (!hub.captureSession) {
            return;
        }
        // The session duration for browser sessions does not track a meaningful
        // concept that can be used as a metric.
        // Automatically captured sessions are akin to page views, and thus we
        // discard their duration.
        startSessionOnHub(hub);
        // We want to create a session for every navigation as well
        addInstrumentationHandler('history', function (_a) {
            var from = _a.from, to = _a.to;
            // Don't create an additional session for the initial route or if the location did not change
            if (!(from === undefined || from === to)) {
                startSessionOnHub(getCurrentHub());
            }
        });
    }

    // TODO: Remove in the next major release and rely only on @sentry/core SDK_VERSION and SdkInfo metadata
    var SDK_NAME = 'sentry.javascript.browser';

    var windowIntegrations = {};
    // This block is needed to add compatibility with the integrations packages when used with a CDN
    var _window = getGlobalObject();
    if (_window.Sentry && _window.Sentry.Integrations) {
        windowIntegrations = _window.Sentry.Integrations;
    }
    var INTEGRATIONS = __assign(__assign(__assign({}, windowIntegrations), CoreIntegrations), BrowserIntegrations);

    exports.BrowserClient = BrowserClient;
    exports.Hub = Hub;
    exports.Integrations = INTEGRATIONS;
    exports.SDK_NAME = SDK_NAME;
    exports.SDK_VERSION = SDK_VERSION;
    exports.Scope = Scope;
    exports.Session = Session;
    exports.Transports = index;
    exports.addBreadcrumb = addBreadcrumb;
    exports.addGlobalEventProcessor = addGlobalEventProcessor;
    exports.captureEvent = captureEvent;
    exports.captureException = captureException;
    exports.captureMessage = captureMessage;
    exports.close = close;
    exports.configureScope = configureScope;
    exports.defaultIntegrations = defaultIntegrations;
    exports.eventFromException = eventFromException;
    exports.eventFromMessage = eventFromMessage;
    exports.flush = flush;
    exports.forceLoad = forceLoad;
    exports.getCurrentHub = getCurrentHub;
    exports.getHubFromCarrier = getHubFromCarrier;
    exports.init = init;
    exports.injectReportDialog = injectReportDialog;
    exports.lastEventId = lastEventId;
    exports.makeMain = makeMain;
    exports.onLoad = onLoad;
    exports.setContext = setContext;
    exports.setExtra = setExtra;
    exports.setExtras = setExtras;
    exports.setTag = setTag;
    exports.setTags = setTags;
    exports.setUser = setUser;
    exports.showReportDialog = showReportDialog;
    exports.startTransaction = startTransaction;
    exports.withScope = withScope;
    exports.wrap = wrap;

    return exports;

})({});
//# sourceMappingURL=bundle.js.map
