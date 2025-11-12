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
exports.defaultStackParser = exports.defaultStackLineParsers = exports.opera11StackLineParser = exports.opera10StackLineParser = exports.winjsStackLineParser = exports.geckoStackLineParser = exports.chromeStackLineParser = void 0;
exports.reverseAndStripFrames = reverseAndStripFrames;
exports.createStackParser = createStackParser;
// 💖 open source
// This was originally forked from https://github.com/csnover/TraceKit, and was largely
// re-written as part of raven - js.
//
// This code was later copied to the JavaScript mono - repo and further modified and
// refactored over the years.
// Copyright (c) 2013 Onur Can Cakmak onur.cakmak@gmail.com and all TraceKit contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files(the 'Software'), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and / or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
var core_1 = require("@posthog/core");
var WEBPACK_ERROR_REGEXP = /\(error: (.*)\)/;
var STACKTRACE_FRAME_LIMIT = 50;
var UNKNOWN_FUNCTION = '?';
var OPERA10_PRIORITY = 10;
var OPERA11_PRIORITY = 20;
var CHROME_PRIORITY = 30;
var WINJS_PRIORITY = 40;
var GECKO_PRIORITY = 50;
function createFrame(filename, func, lineno, colno) {
    var frame = {
        platform: 'web:javascript',
        filename: filename,
        function: func === '<anonymous>' ? UNKNOWN_FUNCTION : func,
        in_app: true, // All browser frames are considered in_app
    };
    if (!(0, core_1.isUndefined)(lineno)) {
        frame.lineno = lineno;
    }
    if (!(0, core_1.isUndefined)(colno)) {
        frame.colno = colno;
    }
    return frame;
}
// This regex matches frames that have no function name (ie. are at the top level of a module).
// For example "at http://localhost:5000//script.js:1:126"
// Frames _with_ function names usually look as follows: "at commitLayoutEffects (react-dom.development.js:23426:1)"
var chromeRegexNoFnName = /^\s*at (\S+?)(?::(\d+))(?::(\d+))\s*$/i;
// This regex matches all the frames that have a function name.
var chromeRegex = /^\s*at (?:(.+?\)(?: \[.+\])?|.*?) ?\((?:address at )?)?(?:async )?((?:<anonymous>|[-a-z]+:|.*bundle|\/)?.*?)(?::(\d+))?(?::(\d+))?\)?\s*$/i;
var chromeEvalRegex = /\((\S*)(?::(\d+))(?::(\d+))\)/;
// Chromium based browsers: Chrome, Brave, new Opera, new Edge
// We cannot call this variable `chrome` because it can conflict with global `chrome` variable in certain environments
// See: https://github.com/getsentry/sentry-javascript/issues/6880
var chromeStackParserFn = function (line) {
    // If the stack line has no function name, we need to parse it differently
    var noFnParts = chromeRegexNoFnName.exec(line);
    if (noFnParts) {
        var _a = __read(noFnParts, 4), filename = _a[1], line_1 = _a[2], col = _a[3];
        return createFrame(filename, UNKNOWN_FUNCTION, +line_1, +col);
    }
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
        var _b = __read(extractSafariExtensionDetails(parts[1] || UNKNOWN_FUNCTION, parts[2]), 2), func = _b[0], filename = _b[1];
        return createFrame(filename, func, parts[3] ? +parts[3] : undefined, parts[4] ? +parts[4] : undefined);
    }
    return;
};
exports.chromeStackLineParser = [CHROME_PRIORITY, chromeStackParserFn];
// gecko regex: `(?:bundle|\d+\.js)`: `bundle` is for react native, `\d+\.js` also but specifically for ram bundles because it
// generates filenames without a prefix like `file://` the filenames in the stacktrace are just 42.js
// We need this specific case for now because we want no other regex to match.
var geckoREgex = /^\s*(.*?)(?:\((.*?)\))?(?:^|@)?((?:[-a-z]+)?:\/.*?|\[native code\]|[^@]*(?:bundle|\d+\.js)|\/[\w\-. /=]+)(?::(\d+))?(?::(\d+))?\s*$/i;
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
exports.geckoStackLineParser = [GECKO_PRIORITY, gecko];
var winjsRegex = /^\s*at (?:((?:\[object object\])?.+) )?\(?((?:[-a-z]+):.*?):(\d+)(?::(\d+))?\)?\s*$/i;
var winjs = function (line) {
    var parts = winjsRegex.exec(line);
    return parts
        ? createFrame(parts[2], parts[1] || UNKNOWN_FUNCTION, +parts[3], parts[4] ? +parts[4] : undefined)
        : undefined;
};
exports.winjsStackLineParser = [WINJS_PRIORITY, winjs];
var opera10Regex = / line (\d+).*script (?:in )?(\S+)(?:: in function (\S+))?$/i;
var opera10 = function (line) {
    var parts = opera10Regex.exec(line);
    return parts ? createFrame(parts[2], parts[3] || UNKNOWN_FUNCTION, +parts[1]) : undefined;
};
exports.opera10StackLineParser = [OPERA10_PRIORITY, opera10];
var opera11Regex = / line (\d+), column (\d+)\s*(?:in (?:<anonymous function: ([^>]+)>|([^)]+))\(.*\))? in (.*):\s*$/i;
var opera11 = function (line) {
    var parts = opera11Regex.exec(line);
    return parts ? createFrame(parts[5], parts[3] || parts[4] || UNKNOWN_FUNCTION, +parts[1], +parts[2]) : undefined;
};
exports.opera11StackLineParser = [OPERA11_PRIORITY, opera11];
exports.defaultStackLineParsers = [exports.chromeStackLineParser, exports.geckoStackLineParser];
exports.defaultStackParser = createStackParser.apply(void 0, __spreadArray([], __read(exports.defaultStackLineParsers), false));
function reverseAndStripFrames(stack) {
    if (!stack.length) {
        return [];
    }
    var localStack = Array.from(stack);
    localStack.reverse();
    return localStack.slice(0, STACKTRACE_FRAME_LIMIT).map(function (frame) { return (__assign(__assign({}, frame), { filename: frame.filename || getLastStackFrame(localStack).filename, function: frame.function || UNKNOWN_FUNCTION })); });
}
function getLastStackFrame(arr) {
    return arr[arr.length - 1] || {};
}
function createStackParser() {
    var parsers = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        parsers[_i] = arguments[_i];
    }
    var sortedParsers = parsers.sort(function (a, b) { return a[0] - b[0]; }).map(function (p) { return p[1]; });
    return function (stack, skipFirstLines) {
        var e_1, _a;
        if (skipFirstLines === void 0) { skipFirstLines = 0; }
        var frames = [];
        var lines = stack.split('\n');
        for (var i = skipFirstLines; i < lines.length; i++) {
            var line = lines[i];
            // Ignore lines over 1kb as they are unlikely to be stack frames.
            // Many of the regular expressions use backtracking which results in run time that increases exponentially with
            // input size. Huge strings can result in hangs/Denial of Service:
            // https://github.com/getsentry/sentry-javascript/issues/2286
            if (line.length > 1024) {
                continue;
            }
            // https://github.com/getsentry/sentry-javascript/issues/5459
            // Remove webpack (error: *) wrappers
            var cleanedLine = WEBPACK_ERROR_REGEXP.test(line) ? line.replace(WEBPACK_ERROR_REGEXP, '$1') : line;
            // https://github.com/getsentry/sentry-javascript/issues/7813
            // Skip Error: lines
            if (cleanedLine.match(/\S*Error: /)) {
                continue;
            }
            try {
                for (var sortedParsers_1 = (e_1 = void 0, __values(sortedParsers)), sortedParsers_1_1 = sortedParsers_1.next(); !sortedParsers_1_1.done; sortedParsers_1_1 = sortedParsers_1.next()) {
                    var parser = sortedParsers_1_1.value;
                    var frame = parser(cleanedLine);
                    if (frame) {
                        frames.push(frame);
                        break;
                    }
                }
            }
            catch (e_1_1) { e_1 = { error: e_1_1 }; }
            finally {
                try {
                    if (sortedParsers_1_1 && !sortedParsers_1_1.done && (_a = sortedParsers_1.return)) _a.call(sortedParsers_1);
                }
                finally { if (e_1) throw e_1.error; }
            }
            if (frames.length >= STACKTRACE_FRAME_LIMIT) {
                break;
            }
        }
        return reverseAndStripFrames(frames);
    };
}
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
            isSafariExtension ? "safari-extension:".concat(filename) : "safari-web-extension:".concat(filename),
        ]
        : [func, filename];
};
//# sourceMappingURL=stack-trace.js.map