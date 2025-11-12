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
exports.SEVEN_MEGABYTES = exports.CONSOLE_LOG_PLUGIN_NAME = exports.MAX_MESSAGE_SIZE = exports.MUTATION_SOURCE_TYPE = exports.PLUGIN_EVENT_TYPE = exports.INCREMENTAL_SNAPSHOT_EVENT_TYPE = exports.META_EVENT_TYPE = exports.FULL_SNAPSHOT_EVENT_TYPE = exports.replacementImageURI = void 0;
exports.circularReferenceReplacer = circularReferenceReplacer;
exports.estimateSize = estimateSize;
exports.ensureMaxMessageSize = ensureMaxMessageSize;
exports.truncateLargeConsoleLogs = truncateLargeConsoleLogs;
exports.splitBuffer = splitBuffer;
var core_1 = require("@posthog/core");
// taken from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Cyclic_object_value#circular_references
function circularReferenceReplacer() {
    var ancestors = [];
    return function (_key, value) {
        if ((0, core_1.isObject)(value)) {
            // `this` is the object that value is contained in,
            // i.e., its direct parent.
            while (ancestors.length > 0 && ancestors[ancestors.length - 1] !== this) {
                ancestors.pop();
            }
            if (ancestors.includes(value)) {
                return '[Circular]';
            }
            ancestors.push(value);
            return value;
        }
        else {
            return value;
        }
    };
}
function estimateSize(sizeable) {
    var _a;
    return ((_a = JSON.stringify(sizeable, circularReferenceReplacer())) === null || _a === void 0 ? void 0 : _a.length) || 0;
}
exports.replacementImageURI = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjE2IiBoZWlnaHQ9IjE2IiBmaWxsPSJibGFjayIvPgo8cGF0aCBkPSJNOCAwSDE2TDAgMTZWOEw4IDBaIiBmaWxsPSIjMkQyRDJEIi8+CjxwYXRoIGQ9Ik0xNiA4VjE2SDhMMTYgOFoiIGZpbGw9IiMyRDJEMkQiLz4KPC9zdmc+Cg==';
exports.FULL_SNAPSHOT_EVENT_TYPE = 2;
exports.META_EVENT_TYPE = 4;
exports.INCREMENTAL_SNAPSHOT_EVENT_TYPE = 3;
exports.PLUGIN_EVENT_TYPE = 6;
exports.MUTATION_SOURCE_TYPE = 0;
exports.MAX_MESSAGE_SIZE = 5000000; // ~5mb
/*
 * Check whether a data payload is nearing 5mb. If it is, it checks the data for
 * data URIs (the likely culprit for large payloads). If it finds data URIs, it either replaces
 * it with a generic image (if it's an image) or removes it.
 * @data {object} the rr-web data object
 * @returns {object} the rr-web data object with data uris filtered out
 */
function ensureMaxMessageSize(data) {
    var e_1, _a;
    var stringifiedData = JSON.stringify(data);
    // Note: with compression, this limit may be able to be increased
    // but we're assuming most of the size is from a data uri which
    // is unlikely to be compressed further
    if (stringifiedData.length > exports.MAX_MESSAGE_SIZE) {
        // Regex that matches the pattern for a dataURI with the shape 'data:{mime type};{encoding},{data}'. It:
        // 1) Checks if the pattern starts with 'data:' (potentially, not at the start of the string)
        // 2) Extracts the mime type of the data uri in the first group
        // 3) Determines when the data URI ends.Depending on if it's used in the src tag or css, it can end with a ) or "
        var dataURIRegex = /data:([\w/\-.]+);(\w+),([^)"]*)/gim;
        var matches = stringifiedData.matchAll(dataURIRegex);
        try {
            for (var matches_1 = __values(matches), matches_1_1 = matches_1.next(); !matches_1_1.done; matches_1_1 = matches_1.next()) {
                var match = matches_1_1.value;
                if (match[1].toLocaleLowerCase().slice(0, 6) === 'image/') {
                    stringifiedData = stringifiedData.replace(match[0], exports.replacementImageURI);
                }
                else {
                    stringifiedData = stringifiedData.replace(match[0], '');
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (matches_1_1 && !matches_1_1.done && (_a = matches_1.return)) _a.call(matches_1);
            }
            finally { if (e_1) throw e_1.error; }
        }
    }
    return { event: JSON.parse(stringifiedData), size: stringifiedData.length };
}
exports.CONSOLE_LOG_PLUGIN_NAME = 'rrweb/console@1'; // The name of the rr-web plugin that emits console logs
// Console logs can be really large. This function truncates large logs
// It's a simple function that just truncates long strings.
// TODO: Ideally this function would have better handling of objects + lists,
// so they could still be rendered in a pretty way after truncation.
function truncateLargeConsoleLogs(_event) {
    var event = _event;
    var MAX_STRING_SIZE = 2000; // Maximum number of characters allowed in a string
    var MAX_STRINGS_PER_LOG = 10; // A log can consist of multiple strings (e.g. consol.log('string1', 'string2'))
    if (event &&
        (0, core_1.isObject)(event) &&
        event.type === exports.PLUGIN_EVENT_TYPE &&
        (0, core_1.isObject)(event.data) &&
        event.data.plugin === exports.CONSOLE_LOG_PLUGIN_NAME) {
        // Note: event.data.payload.payload comes from rr-web, and is an array of strings
        if (event.data.payload.payload.length > MAX_STRINGS_PER_LOG) {
            event.data.payload.payload = event.data.payload.payload.slice(0, MAX_STRINGS_PER_LOG);
            event.data.payload.payload.push('...[truncated]');
        }
        var updatedPayload = [];
        for (var i = 0; i < event.data.payload.payload.length; i++) {
            if (event.data.payload.payload[i] && // Value can be null
                event.data.payload.payload[i].length > MAX_STRING_SIZE) {
                updatedPayload.push(event.data.payload.payload[i].slice(0, MAX_STRING_SIZE) + '...[truncated]');
            }
            else {
                updatedPayload.push(event.data.payload.payload[i]);
            }
        }
        event.data.payload.payload = updatedPayload;
        // Return original type
        return _event;
    }
    return _event;
}
exports.SEVEN_MEGABYTES = 1024 * 1024 * 7 * 0.9; // ~7mb (with some wiggle room)
// recursively splits large buffers into smaller ones
// uses a pretty high size limit to avoid splitting too much
function splitBuffer(buffer, sizeLimit) {
    if (sizeLimit === void 0) { sizeLimit = exports.SEVEN_MEGABYTES; }
    if (buffer.size >= sizeLimit && buffer.data.length > 1) {
        var half = Math.floor(buffer.data.length / 2);
        var firstHalf = buffer.data.slice(0, half);
        var secondHalf = buffer.data.slice(half);
        return [
            splitBuffer({
                size: estimateSize(firstHalf),
                data: firstHalf,
                sessionId: buffer.sessionId,
                windowId: buffer.windowId,
            }),
            splitBuffer({
                size: estimateSize(secondHalf),
                data: secondHalf,
                sessionId: buffer.sessionId,
                windowId: buffer.windowId,
            }),
        ].flatMap(function (x) { return x; });
    }
    else {
        return [buffer];
    }
}
//# sourceMappingURL=sessionrecording-utils.js.map