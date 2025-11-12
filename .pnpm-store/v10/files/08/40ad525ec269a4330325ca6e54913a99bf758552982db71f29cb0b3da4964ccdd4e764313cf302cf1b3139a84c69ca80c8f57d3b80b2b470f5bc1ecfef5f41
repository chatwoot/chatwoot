"use strict";
/// <reference lib="dom" />
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
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
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
exports.getRecordNetworkPlugin = exports.NETWORK_PLUGIN_NAME = void 0;
exports.findLast = findLast;
exports.shouldRecordBody = shouldRecordBody;
var core_1 = require("@posthog/core");
var type_utils_1 = require("../../../utils/type-utils");
var logger_1 = require("../../../utils/logger");
var request_utils_1 = require("../../../utils/request-utils");
var patch_1 = require("../rrweb-plugins/patch");
var denylist_1 = require("../../../extensions/replay/external/denylist");
var config_1 = require("../config");
var logger = (0, logger_1.createLogger)('[Recorder]');
var isNavigationTiming = function (entry) {
    return entry.entryType === 'navigation';
};
var isResourceTiming = function (entry) { return entry.entryType === 'resource'; };
function findLast(array, predicate) {
    var length = array.length;
    for (var i = length - 1; i >= 0; i -= 1) {
        if (predicate(array[i])) {
            return array[i];
        }
    }
    return undefined;
}
function initPerformanceObserver(cb, win, options) {
    // if we are only observing timings then we could have a single observer for all types, with buffer true,
    // but we are going to filter by initiatorType _if we are wrapping fetch and xhr as the wrapped functions
    // will deal with those.
    // so we have a block which captures requests from before fetch/xhr is wrapped
    // these are marked `isInitial` so playback can display them differently if needed
    // they will never have method/status/headers/body because they are pre-wrapping that provides that
    if (options.recordInitialRequests) {
        var initialPerformanceEntries = win.performance
            .getEntries()
            .filter(function (entry) {
            return isNavigationTiming(entry) ||
                (isResourceTiming(entry) && options.initiatorTypes.includes(entry.initiatorType));
        });
        cb({
            requests: initialPerformanceEntries.flatMap(function (entry) {
                return prepareRequest({ entry: entry, method: undefined, status: undefined, networkRequest: {}, isInitial: true });
            }),
            isInitial: true,
        });
    }
    var observer = new win.PerformanceObserver(function (entries) {
        // if recordBody or recordHeaders is true then we don't want to record fetch or xhr here
        // as the wrapped functions will do that. Otherwise, this filter becomes a noop
        // because we do want to record them here
        var wrappedInitiatorFilter = function (entry) {
            return options.recordBody || options.recordHeaders
                ? entry.initiatorType !== 'xmlhttprequest' && entry.initiatorType !== 'fetch'
                : true;
        };
        var performanceEntries = entries.getEntries().filter(function (entry) {
            return isNavigationTiming(entry) ||
                (isResourceTiming(entry) &&
                    options.initiatorTypes.includes(entry.initiatorType) &&
                    // TODO if we are _only_ capturing timing we don't want to filter initiator here
                    wrappedInitiatorFilter(entry));
        });
        cb({
            requests: performanceEntries.flatMap(function (entry) {
                return prepareRequest({ entry: entry, method: undefined, status: undefined, networkRequest: {} });
            }),
        });
    });
    // compat checked earlier
    // eslint-disable-next-line compat/compat
    var entryTypes = PerformanceObserver.supportedEntryTypes.filter(function (x) {
        return options.performanceEntryTypeToObserve.includes(x);
    });
    // initial records are gathered above, so we don't need to observe and buffer each type separately
    observer.observe({ entryTypes: entryTypes });
    return function () {
        observer.disconnect();
    };
}
function shouldRecordHeaders(type, recordHeaders) {
    return !!recordHeaders && ((0, core_1.isBoolean)(recordHeaders) || recordHeaders[type]);
}
function shouldRecordBody(_a) {
    var type = _a.type, recordBody = _a.recordBody, headers = _a.headers, url = _a.url;
    function matchesContentType(contentTypes) {
        var contentTypeHeader = Object.keys(headers).find(function (key) { return key.toLowerCase() === 'content-type'; });
        var contentType = contentTypeHeader && headers[contentTypeHeader];
        return contentTypes.some(function (ct) { return contentType === null || contentType === void 0 ? void 0 : contentType.includes(ct); });
    }
    /**
     * particularly in canvas applications we see many requests to blob URLs
     * e.g. blob:https://video_url
     * these blob/object URLs are local to the browser, we can never capture that body
     * so we can just return false here
     */
    function isBlobURL(url) {
        try {
            if (typeof url === 'string') {
                return url.startsWith('blob:');
            }
            if (url instanceof URL) {
                return url.protocol === 'blob:';
            }
            if (url instanceof Request) {
                return isBlobURL(url.url);
            }
            return false;
        }
        catch (_a) {
            return false;
        }
    }
    if (!recordBody)
        return false;
    if (isBlobURL(url))
        return false;
    if ((0, core_1.isBoolean)(recordBody))
        return true;
    if ((0, core_1.isArray)(recordBody))
        return matchesContentType(recordBody);
    var recordBodyType = recordBody[type];
    if ((0, core_1.isBoolean)(recordBodyType))
        return recordBodyType;
    return matchesContentType(recordBodyType);
}
function getRequestPerformanceEntry(win_1, initiatorType_1, url_1, start_1, end_1) {
    return __awaiter(this, arguments, void 0, function (win, initiatorType, url, start, end, attempt) {
        var urlPerformanceEntries, performanceEntry;
        if (attempt === void 0) { attempt = 0; }
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    if (attempt > 10) {
                        logger.warn('Failed to get performance entry for request', { url: url, initiatorType: initiatorType });
                        return [2 /*return*/, null];
                    }
                    urlPerformanceEntries = win.performance.getEntriesByName(url);
                    performanceEntry = findLast(urlPerformanceEntries, function (entry) {
                        return isResourceTiming(entry) &&
                            entry.initiatorType === initiatorType &&
                            ((0, core_1.isUndefined)(start) || entry.startTime >= start) &&
                            ((0, core_1.isUndefined)(end) || entry.startTime <= end);
                    });
                    if (!!performanceEntry) return [3 /*break*/, 2];
                    return [4 /*yield*/, new Promise(function (resolve) { return setTimeout(resolve, 50 * attempt); })];
                case 1:
                    _a.sent();
                    return [2 /*return*/, getRequestPerformanceEntry(win, initiatorType, url, start, end, attempt + 1)];
                case 2: return [2 /*return*/, performanceEntry];
            }
        });
    });
}
/**
 * According to MDN https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/response
 * xhr response is typed as any but can be an ArrayBuffer, a Blob, a Document, a JavaScript object,
 * or a string, depending on the value of XMLHttpRequest.responseType, that contains the response entity body.
 *
 * XHR request body is Document | XMLHttpRequestBodyInit | null | undefined
 */
function _tryReadXHRBody(_a) {
    var body = _a.body, options = _a.options, url = _a.url;
    if ((0, core_1.isNullish)(body)) {
        return null;
    }
    var _b = (0, denylist_1.isHostOnDenyList)(url, options), hostname = _b.hostname, isHostDenied = _b.isHostDenied;
    if (isHostDenied) {
        return hostname + ' is in deny list';
    }
    if ((0, core_1.isString)(body)) {
        return body;
    }
    if ((0, type_utils_1.isDocument)(body)) {
        return body.textContent;
    }
    if ((0, core_1.isFormData)(body)) {
        return (0, request_utils_1.formDataToQuery)(body);
    }
    if ((0, core_1.isObject)(body)) {
        try {
            return JSON.stringify(body);
        }
        catch (_c) {
            return '[SessionReplay] Failed to stringify response object';
        }
    }
    return '[SessionReplay] Cannot read body of type ' + toString.call(body);
}
function initXhrObserver(cb, win, options) {
    if (!options.initiatorTypes.includes('xmlhttprequest')) {
        return function () {
            //
        };
    }
    var recordRequestHeaders = shouldRecordHeaders('request', options.recordHeaders);
    var recordResponseHeaders = shouldRecordHeaders('response', options.recordHeaders);
    var restorePatch = (0, patch_1.patch)(win.XMLHttpRequest.prototype, 'open', 
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    function (originalOpen) {
        return function (method, url, async, username, password) {
            if (async === void 0) { async = true; }
            // because this function is returned in its actual context `this` _is_ an XMLHttpRequest
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            var xhr = this;
            // check IE earlier than this, we only initialize if Request is present
            // eslint-disable-next-line compat/compat
            var req = new Request(url);
            var networkRequest = {};
            var start;
            var end;
            var requestHeaders = {};
            var originalSetRequestHeader = xhr.setRequestHeader.bind(xhr);
            xhr.setRequestHeader = function (header, value) {
                requestHeaders[header] = value;
                return originalSetRequestHeader(header, value);
            };
            if (recordRequestHeaders) {
                networkRequest.requestHeaders = requestHeaders;
            }
            var originalSend = xhr.send.bind(xhr);
            xhr.send = function (body) {
                if (shouldRecordBody({
                    type: 'request',
                    headers: requestHeaders,
                    url: url,
                    recordBody: options.recordBody,
                })) {
                    networkRequest.requestBody = _tryReadXHRBody({ body: body, options: options, url: url });
                }
                start = win.performance.now();
                return originalSend(body);
            };
            // This is very tricky code, and making it passive won't bring many performance benefits,
            // so let's ignore the rule here.
            // eslint-disable-next-line posthog-js/no-add-event-listener
            xhr.addEventListener('readystatechange', function () {
                if (xhr.readyState !== xhr.DONE) {
                    return;
                }
                end = win.performance.now();
                var responseHeaders = {};
                var rawHeaders = xhr.getAllResponseHeaders();
                var headers = rawHeaders.trim().split(/[\r\n]+/);
                headers.forEach(function (line) {
                    var parts = line.split(': ');
                    var header = parts.shift();
                    var value = parts.join(': ');
                    if (header) {
                        responseHeaders[header] = value;
                    }
                });
                if (recordResponseHeaders) {
                    networkRequest.responseHeaders = responseHeaders;
                }
                if (shouldRecordBody({
                    type: 'response',
                    headers: responseHeaders,
                    url: url,
                    recordBody: options.recordBody,
                })) {
                    networkRequest.responseBody = _tryReadXHRBody({ body: xhr.response, options: options, url: url });
                }
                getRequestPerformanceEntry(win, 'xmlhttprequest', req.url, start, end)
                    .then(function (entry) {
                    var requests = prepareRequest({
                        entry: entry,
                        method: method,
                        status: xhr === null || xhr === void 0 ? void 0 : xhr.status,
                        networkRequest: networkRequest,
                        start: start,
                        end: end,
                        url: url.toString(),
                        initiatorType: 'xmlhttprequest',
                    });
                    cb({ requests: requests });
                })
                    .catch(function () {
                    //
                });
            });
            originalOpen.call(xhr, method, url, async, username, password);
        };
    });
    return function () {
        restorePatch();
    };
}
/**
 *  Check if this PerformanceEntry is either a PerformanceResourceTiming or a PerformanceNavigationTiming
 *  NB PerformanceNavigationTiming extends PerformanceResourceTiming
 *  Here we don't care which interface it implements as both expose `serverTimings`
 */
var exposesServerTiming = function (event) {
    return !(0, core_1.isNull)(event) && (event.entryType === 'navigation' || event.entryType === 'resource');
};
function prepareRequest(_a) {
    var e_1, _b;
    var entry = _a.entry, method = _a.method, status = _a.status, networkRequest = _a.networkRequest, isInitial = _a.isInitial, start = _a.start, end = _a.end, url = _a.url, initiatorType = _a.initiatorType;
    start = entry ? entry.startTime : start;
    end = entry ? entry.responseEnd : end;
    // kudos to sentry javascript sdk for excellent background on why to use Date.now() here
    // https://github.com/getsentry/sentry-javascript/blob/e856e40b6e71a73252e788cd42b5260f81c9c88e/packages/utils/src/time.ts#L70
    // can't start observer if performance.now() is not available
    // eslint-disable-next-line compat/compat
    var timeOrigin = Math.floor(Date.now() - performance.now());
    // clickhouse can't ingest timestamps that are floats
    // (in this case representing fractions of a millisecond we don't care about anyway)
    // use timeOrigin if we really can't gather a start time
    var timestamp = Math.floor(timeOrigin + (start || 0));
    var entryJSON = entry ? entry.toJSON() : { name: url };
    var requests = [
        __assign(__assign({}, entryJSON), { startTime: (0, core_1.isUndefined)(start) ? undefined : Math.round(start), endTime: (0, core_1.isUndefined)(end) ? undefined : Math.round(end), timeOrigin: timeOrigin, timestamp: timestamp, method: method, initiatorType: initiatorType ? initiatorType : entry ? entry.initiatorType : undefined, status: status, requestHeaders: networkRequest.requestHeaders, requestBody: networkRequest.requestBody, responseHeaders: networkRequest.responseHeaders, responseBody: networkRequest.responseBody, isInitial: isInitial }),
    ];
    if (exposesServerTiming(entry)) {
        try {
            for (var _c = __values(entry.serverTiming || []), _d = _c.next(); !_d.done; _d = _c.next()) {
                var timing = _d.value;
                requests.push({
                    timeOrigin: timeOrigin,
                    timestamp: timestamp,
                    startTime: Math.round(entry.startTime),
                    name: timing.name,
                    duration: timing.duration,
                    // the spec has a closed list of possible types
                    // https://developer.mozilla.org/en-US/docs/Web/API/PerformanceEntry/entryType
                    // but, we need to know this was a server timing so that we know to
                    // match it to the appropriate navigation or resource timing
                    // that matching will have to be on timestamp and $current_url
                    entryType: 'serverTiming',
                });
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_d && !_d.done && (_b = _c.return)) _b.call(_c);
            }
            finally { if (e_1) throw e_1.error; }
        }
    }
    return requests;
}
var contentTypePrefixDenyList = ['video/', 'audio/'];
function _checkForCannotReadResponseBody(_a) {
    var _b;
    var r = _a.r, options = _a.options, url = _a.url;
    if (r.headers.get('Transfer-Encoding') === 'chunked') {
        return 'Chunked Transfer-Encoding is not supported';
    }
    // `get` and `has` are case-insensitive
    // but return the header value with the casing that was supplied
    var contentType = (_b = r.headers.get('Content-Type')) === null || _b === void 0 ? void 0 : _b.toLowerCase();
    var contentTypeIsDenied = contentTypePrefixDenyList.some(function (prefix) { return contentType === null || contentType === void 0 ? void 0 : contentType.startsWith(prefix); });
    if (contentType && contentTypeIsDenied) {
        return "Content-Type ".concat(contentType, " is not supported");
    }
    var _c = (0, denylist_1.isHostOnDenyList)(url, options), hostname = _c.hostname, isHostDenied = _c.isHostDenied;
    if (isHostDenied) {
        return hostname + ' is in deny list';
    }
    return null;
}
function _tryReadBody(r) {
    // there are now already multiple places where we're using Promise...
    // eslint-disable-next-line compat/compat
    return new Promise(function (resolve, reject) {
        var timeout = setTimeout(function () { return resolve('[SessionReplay] Timeout while trying to read body'); }, 500);
        try {
            r.clone()
                .text()
                .then(function (txt) { return resolve(txt); }, function (reason) { return reject(reason); })
                .finally(function () { return clearTimeout(timeout); });
        }
        catch (_a) {
            clearTimeout(timeout);
            resolve('[SessionReplay] Failed to read body');
        }
    });
}
function _tryReadRequestBody(_a) {
    return __awaiter(this, arguments, void 0, function (_b) {
        var _c, hostname, isHostDenied;
        var r = _b.r, options = _b.options, url = _b.url;
        return __generator(this, function (_d) {
            _c = (0, denylist_1.isHostOnDenyList)(url, options), hostname = _c.hostname, isHostDenied = _c.isHostDenied;
            if (isHostDenied) {
                return [2 /*return*/, Promise.resolve(hostname + ' is in deny list')];
            }
            return [2 /*return*/, _tryReadBody(r)];
        });
    });
}
function _tryReadResponseBody(_a) {
    return __awaiter(this, arguments, void 0, function (_b) {
        var cannotReadBodyReason;
        var r = _b.r, options = _b.options, url = _b.url;
        return __generator(this, function (_c) {
            cannotReadBodyReason = _checkForCannotReadResponseBody({ r: r, options: options, url: url });
            if (!(0, core_1.isNull)(cannotReadBodyReason)) {
                return [2 /*return*/, Promise.resolve(cannotReadBodyReason)];
            }
            return [2 /*return*/, _tryReadBody(r)];
        });
    });
}
function initFetchObserver(cb, win, options) {
    if (!options.initiatorTypes.includes('fetch')) {
        return function () {
            //
        };
    }
    var recordRequestHeaders = shouldRecordHeaders('request', options.recordHeaders);
    var recordResponseHeaders = shouldRecordHeaders('response', options.recordHeaders);
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    var restorePatch = (0, patch_1.patch)(win, 'fetch', function (originalFetch) {
        return function (url, init) {
            return __awaiter(this, void 0, void 0, function () {
                var req, res, networkRequest, start, end, requestHeaders_1, _a, responseHeaders_1, _b;
                return __generator(this, function (_c) {
                    switch (_c.label) {
                        case 0:
                            req = new Request(url, init);
                            networkRequest = {};
                            _c.label = 1;
                        case 1:
                            _c.trys.push([1, , 7, 8]);
                            requestHeaders_1 = {};
                            req.headers.forEach(function (value, header) {
                                requestHeaders_1[header] = value;
                            });
                            if (recordRequestHeaders) {
                                networkRequest.requestHeaders = requestHeaders_1;
                            }
                            if (!shouldRecordBody({
                                type: 'request',
                                headers: requestHeaders_1,
                                url: url,
                                recordBody: options.recordBody,
                            })) return [3 /*break*/, 3];
                            _a = networkRequest;
                            return [4 /*yield*/, _tryReadRequestBody({ r: req, options: options, url: url })];
                        case 2:
                            _a.requestBody = _c.sent();
                            _c.label = 3;
                        case 3:
                            start = win.performance.now();
                            return [4 /*yield*/, originalFetch(req)];
                        case 4:
                            res = _c.sent();
                            end = win.performance.now();
                            responseHeaders_1 = {};
                            res.headers.forEach(function (value, header) {
                                responseHeaders_1[header] = value;
                            });
                            if (recordResponseHeaders) {
                                networkRequest.responseHeaders = responseHeaders_1;
                            }
                            if (!shouldRecordBody({
                                type: 'response',
                                headers: responseHeaders_1,
                                url: url,
                                recordBody: options.recordBody,
                            })) return [3 /*break*/, 6];
                            _b = networkRequest;
                            return [4 /*yield*/, _tryReadResponseBody({ r: res, options: options, url: url })];
                        case 5:
                            _b.responseBody = _c.sent();
                            _c.label = 6;
                        case 6: return [2 /*return*/, res];
                        case 7:
                            getRequestPerformanceEntry(win, 'fetch', req.url, start, end)
                                .then(function (entry) {
                                var requests = prepareRequest({
                                    entry: entry,
                                    method: req.method,
                                    status: res === null || res === void 0 ? void 0 : res.status,
                                    networkRequest: networkRequest,
                                    start: start,
                                    end: end,
                                    url: req.url,
                                    initiatorType: 'fetch',
                                });
                                cb({ requests: requests });
                            })
                                .catch(function () {
                                //
                            });
                            return [7 /*endfinally*/];
                        case 8: return [2 /*return*/];
                    }
                });
            });
        };
    });
    return function () {
        restorePatch();
    };
}
var initialisedHandler = null;
function initNetworkObserver(callback, win, // top window or in an iframe
options) {
    if (!('performance' in win)) {
        return function () {
            //
        };
    }
    if (initialisedHandler) {
        logger.warn('Network observer already initialised, doing nothing');
        return function () {
            // the first caller should already have this handler and will be responsible for teardown
        };
    }
    var networkOptions = (options ? Object.assign({}, config_1.defaultNetworkOptions, options) : config_1.defaultNetworkOptions);
    var cb = function (data) {
        var requests = [];
        data.requests.forEach(function (request) {
            var maskedRequest = networkOptions.maskRequestFn(request);
            if (maskedRequest) {
                requests.push(maskedRequest);
            }
        });
        if (requests.length > 0) {
            callback(__assign(__assign({}, data), { requests: requests }));
        }
    };
    var performanceObserver = initPerformanceObserver(cb, win, networkOptions);
    // only wrap fetch and xhr if headers or body are being recorded
    var xhrObserver = function () { };
    var fetchObserver = function () { };
    if (networkOptions.recordHeaders || networkOptions.recordBody) {
        xhrObserver = initXhrObserver(cb, win, networkOptions);
        fetchObserver = initFetchObserver(cb, win, networkOptions);
    }
    initialisedHandler = function () {
        performanceObserver();
        xhrObserver();
        fetchObserver();
    };
    return initialisedHandler;
}
// use the plugin name so that when this functionality is adopted into rrweb
// we can remove this plugin and use the core functionality with the same data
exports.NETWORK_PLUGIN_NAME = 'rrweb/network@1';
// TODO how should this be typed?
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
var getRecordNetworkPlugin = function (options) {
    return {
        name: exports.NETWORK_PLUGIN_NAME,
        observer: initNetworkObserver,
        options: options,
    };
};
exports.getRecordNetworkPlugin = getRecordNetworkPlugin;
// rrweb/networ@1 ends
//# sourceMappingURL=network-plugin.js.map