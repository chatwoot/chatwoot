"use strict";
// Portions of this file are derived from getsentry/sentry-javascript by Software, Inc. dba Sentry
// Licensed under the MIT License
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __read = (this && this.__read) || function (o, n) {
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
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseStackFrames = parseStackFrames;
exports.applyChunkIds = applyChunkIds;
exports.extractMessage = extractMessage;
exports.errorToProperties = errorToProperties;
exports.unhandledRejectionToProperties = unhandledRejectionToProperties;
var type_checking_1 = require("./type-checking");
var stack_trace_1 = require("./stack-trace");
var core_1 = require("@posthog/core");
var types_1 = require("../../types");
var chunk_ids_1 = require("./chunk-ids");
/**
 * based on the very wonderful MIT licensed Sentry SDK
 */
var ERROR_TYPES_PATTERN = /^(?:[Uu]ncaught (?:exception: )?)?(?:((?:Eval|Internal|Range|Reference|Syntax|Type|URI|)Error): )?(.*)$/i;
function parseStackFrames(ex, framesToPop) {
    if (framesToPop === void 0) { framesToPop = 0; }
    // Access and store the stacktrace property before doing ANYTHING
    // else to it because Opera is not very good at providing it
    // reliably in other circumstances.
    var stacktrace = ex.stacktrace || ex.stack || '';
    var skipLines = getSkipFirstStackStringLines(ex);
    try {
        var parser = stack_trace_1.defaultStackParser;
        var frames_1 = applyChunkIds(parser(stacktrace, skipLines), parser);
        // frames are reversed so we remove the from the back of the array
        return frames_1.slice(0, frames_1.length - framesToPop);
    }
    catch (_a) {
        // no-empty
    }
    return [];
}
function applyChunkIds(frames, parser) {
    var filenameDebugIdMap = (0, chunk_ids_1.getFilenameToChunkIdMap)(parser);
    frames.forEach(function (frame) {
        if (frame.filename) {
            frame.chunk_id = filenameDebugIdMap[frame.filename];
        }
    });
    return frames;
}
var reactMinifiedRegexp = /Minified React error #\d+;/i;
/**
 * Certain known React errors contain links that would be falsely
 * parsed as frames. This function check for these errors and
 * returns number of the stack string lines to skip.
 */
function getSkipFirstStackStringLines(ex) {
    if (ex && reactMinifiedRegexp.test(ex.message)) {
        return 1;
    }
    return 0;
}
function exceptionFromError(error, metadata) {
    var _a, _b;
    var frames = parseStackFrames(error);
    var handled = (_a = metadata === null || metadata === void 0 ? void 0 : metadata.handled) !== null && _a !== void 0 ? _a : true;
    var synthetic = (_b = metadata === null || metadata === void 0 ? void 0 : metadata.synthetic) !== null && _b !== void 0 ? _b : false;
    var exceptionType = (metadata === null || metadata === void 0 ? void 0 : metadata.overrideExceptionType) ? metadata.overrideExceptionType : error.name;
    var exceptionMessage = extractMessage(error);
    return {
        type: exceptionType,
        value: exceptionMessage,
        stacktrace: {
            frames: frames,
            type: 'raw',
        },
        mechanism: {
            handled: handled,
            synthetic: synthetic,
        },
    };
}
function exceptionListFromError(error, metadata) {
    var exception = exceptionFromError(error, metadata);
    if (error.cause && (0, type_checking_1.isError)(error.cause) && error.cause !== error) {
        // Cause could be an object or a string
        // For now we only support error causes
        // See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/cause
        return __spreadArray([
            exception
        ], __read(exceptionListFromError(error.cause, {
            handled: metadata === null || metadata === void 0 ? void 0 : metadata.handled,
            synthetic: metadata === null || metadata === void 0 ? void 0 : metadata.synthetic,
        })), false);
    }
    return [exception];
}
function errorPropertiesFromError(error, metadata) {
    return {
        $exception_list: exceptionListFromError(error, metadata),
        $exception_level: 'error',
    };
}
/**
 * There are cases where stacktrace.message is an Event object
 * https://github.com/getsentry/sentry-javascript/issues/1949
 * In this specific case we try to extract stacktrace.message.error.message
 */
function extractMessage(err) {
    var message = err.message;
    if (message.error && typeof message.error.message === 'string') {
        return String(message.error.message);
    }
    return String(message);
}
function errorPropertiesFromString(candidate, metadata) {
    var _a, _b, _c;
    // Defaults for metadata are based on what the error candidate is.
    var handled = (_a = metadata === null || metadata === void 0 ? void 0 : metadata.handled) !== null && _a !== void 0 ? _a : true;
    var synthetic = (_b = metadata === null || metadata === void 0 ? void 0 : metadata.synthetic) !== null && _b !== void 0 ? _b : true;
    var exceptionType = (metadata === null || metadata === void 0 ? void 0 : metadata.overrideExceptionType)
        ? metadata.overrideExceptionType
        : ((_c = metadata === null || metadata === void 0 ? void 0 : metadata.defaultExceptionType) !== null && _c !== void 0 ? _c : 'Error');
    var exceptionMessage = candidate ? candidate : metadata === null || metadata === void 0 ? void 0 : metadata.defaultExceptionMessage;
    var exception = {
        type: exceptionType,
        value: exceptionMessage,
        mechanism: {
            handled: handled,
            synthetic: synthetic,
        },
    };
    if (metadata === null || metadata === void 0 ? void 0 : metadata.syntheticException) {
        // Kludge: strip the last frame from a synthetically created error
        // so that it does not appear in a users stack trace
        var frames_2 = parseStackFrames(metadata.syntheticException, 1);
        if (frames_2.length) {
            exception.stacktrace = { frames: frames_2, type: 'raw' };
        }
    }
    return {
        $exception_list: [exception],
        $exception_level: 'error',
    };
}
/**
 * Given any captured exception, extract its keys and create a sorted
 * and truncated list that will be used inside the event message.
 * eg. `Non-error exception captured with keys: foo, bar, baz`
 */
function extractExceptionKeysForMessage(exception, maxLength) {
    if (maxLength === void 0) { maxLength = 40; }
    var keys = Object.keys(exception);
    keys.sort();
    if (!keys.length) {
        return '[object has no keys]';
    }
    for (var i = keys.length; i > 0; i--) {
        var serialized = keys.slice(0, i).join(', ');
        if (serialized.length > maxLength) {
            continue;
        }
        if (i === keys.length) {
            return serialized;
        }
        return serialized.length <= maxLength ? serialized : "".concat(serialized.slice(0, maxLength), "...");
    }
    return '';
}
function isSeverityLevel(x) {
    return (0, core_1.isString)(x) && !(0, core_1.isEmptyString)(x) && types_1.severityLevels.indexOf(x) >= 0;
}
function errorPropertiesFromObject(candidate, metadata) {
    var _a, _b;
    // Defaults for metadata are based on what the error candidate is.
    var handled = (_a = metadata === null || metadata === void 0 ? void 0 : metadata.handled) !== null && _a !== void 0 ? _a : true;
    var synthetic = (_b = metadata === null || metadata === void 0 ? void 0 : metadata.synthetic) !== null && _b !== void 0 ? _b : true;
    var exceptionType = (metadata === null || metadata === void 0 ? void 0 : metadata.overrideExceptionType)
        ? metadata.overrideExceptionType
        : (0, type_checking_1.isEvent)(candidate)
            ? candidate.constructor.name
            : 'Error';
    var exceptionMessage = "Non-Error 'exception' captured with keys: ".concat(extractExceptionKeysForMessage(candidate));
    var exception = {
        type: exceptionType,
        value: exceptionMessage,
        mechanism: {
            handled: handled,
            synthetic: synthetic,
        },
    };
    if (metadata === null || metadata === void 0 ? void 0 : metadata.syntheticException) {
        // Kludge: strip the last frame from a synthetically created error
        // so that it does not appear in a users stack trace
        var frames_3 = parseStackFrames(metadata === null || metadata === void 0 ? void 0 : metadata.syntheticException, 1);
        if (frames_3.length) {
            exception.stacktrace = { frames: frames_3, type: 'raw' };
        }
    }
    return {
        $exception_list: [exception],
        $exception_level: isSeverityLevel(candidate.level) ? candidate.level : 'error',
    };
}
function errorToProperties(_a, metadata) {
    var error = _a.error, event = _a.event;
    var errorProperties = { $exception_list: [] };
    var candidate = error || event;
    if ((0, type_checking_1.isDOMError)(candidate) || (0, type_checking_1.isDOMException)(candidate)) {
        // https://developer.mozilla.org/en-US/docs/Web/API/DOMError
        // https://developer.mozilla.org/en-US/docs/Web/API/DOMException
        var domException = candidate;
        if ((0, type_checking_1.isErrorWithStack)(candidate)) {
            errorProperties = errorPropertiesFromError(candidate, metadata);
        }
        else {
            var name_1 = domException.name || ((0, type_checking_1.isDOMError)(domException) ? 'DOMError' : 'DOMException');
            var message = domException.message ? "".concat(name_1, ": ").concat(domException.message) : name_1;
            var exceptionType = (0, type_checking_1.isDOMError)(domException) ? 'DOMError' : 'DOMException';
            errorProperties = errorPropertiesFromString(message, __assign(__assign({}, metadata), { overrideExceptionType: exceptionType, defaultExceptionMessage: message }));
        }
        if ('code' in domException) {
            errorProperties['$exception_DOMException_code'] = "".concat(domException.code);
        }
        return errorProperties;
    }
    else if ((0, type_checking_1.isErrorEvent)(candidate) && candidate.error) {
        return errorPropertiesFromError(candidate.error, metadata);
    }
    else if ((0, type_checking_1.isError)(candidate)) {
        return errorPropertiesFromError(candidate, metadata);
    }
    else if ((0, type_checking_1.isPlainObject)(candidate) || (0, type_checking_1.isEvent)(candidate)) {
        // group these by using the keys available on the object
        var objectException = candidate;
        return errorPropertiesFromObject(objectException, metadata);
    }
    else if ((0, core_1.isUndefined)(error) && (0, core_1.isString)(event)) {
        var name_2 = 'Error';
        var message = event;
        var groups = event.match(ERROR_TYPES_PATTERN);
        if (groups) {
            name_2 = groups[1];
            message = groups[2];
        }
        return errorPropertiesFromString(message, __assign(__assign({}, metadata), { overrideExceptionType: name_2, defaultExceptionMessage: message }));
    }
    else {
        return errorPropertiesFromString(candidate, metadata);
    }
}
function unhandledRejectionToProperties(_a) {
    var _b = __read(_a, 1), ev = _b[0];
    var error = getUnhandledRejectionError(ev);
    if ((0, type_checking_1.isPrimitive)(error)) {
        return errorPropertiesFromString("Non-Error promise rejection captured with value: ".concat(String(error)), {
            handled: false,
            synthetic: false,
            overrideExceptionType: 'UnhandledRejection',
        });
    }
    return errorToProperties({ event: error }, {
        handled: false,
        overrideExceptionType: 'UnhandledRejection',
        defaultExceptionMessage: String(error),
    });
}
function getUnhandledRejectionError(error) {
    if ((0, type_checking_1.isPrimitive)(error)) {
        return error;
    }
    // dig the object of the rejection out of known event types
    try {
        // PromiseRejectionEvents store the object of the rejection under 'reason'
        // see https://developer.mozilla.org/en-US/docs/Web/API/PromiseRejectionEvent
        if ('reason' in error) {
            return error.reason;
        }
        // something, somewhere, (likely a browser extension) effectively casts PromiseRejectionEvents
        // to CustomEvents, moving the `promise` and `reason` attributes of the PRE into
        // the CustomEvent's `detail` attribute, since they're not part of CustomEvent's spec
        // see https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent and
        // https://github.com/getsentry/sentry-javascript/issues/2380
        if ('detail' in error && 'reason' in error.detail) {
            return error.detail.reason;
        }
    }
    catch (_a) {
        // no-empty
    }
    return error;
}
//# sourceMappingURL=error-conversion.js.map