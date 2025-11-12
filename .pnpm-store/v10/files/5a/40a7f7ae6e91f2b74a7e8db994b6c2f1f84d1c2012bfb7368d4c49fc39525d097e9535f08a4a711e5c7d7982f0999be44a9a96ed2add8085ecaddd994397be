"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.request = exports.jsonStringify = exports.extendURLParams = exports.SUPPORTS_REQUEST = void 0;
var utils_1 = require("./utils");
var config_1 = __importDefault(require("./config"));
var types_1 = require("./types");
var request_utils_1 = require("./utils/request-utils");
var logger_1 = require("./utils/logger");
var globals_1 = require("./utils/globals");
var fflate_1 = require("fflate");
var encode_utils_1 = require("./utils/encode-utils");
// eslint-disable-next-line compat/compat
exports.SUPPORTS_REQUEST = !!globals_1.XMLHttpRequest || !!globals_1.fetch;
var CONTENT_TYPE_PLAIN = 'text/plain';
var CONTENT_TYPE_JSON = 'application/json';
var CONTENT_TYPE_FORM = 'application/x-www-form-urlencoded';
var SIXTY_FOUR_KILOBYTES = 64 * 1024;
/*
 fetch will fail if we request keepalive with a body greater than 64kb
 sets the threshold lower than that so that
 any overhead doesn't push over the threshold after checking here
*/
var KEEP_ALIVE_THRESHOLD = SIXTY_FOUR_KILOBYTES * 0.8;
var extendURLParams = function (url, params) {
    var _a = __read(url.split('?'), 2), baseUrl = _a[0], search = _a[1];
    var newParams = __assign({}, params);
    search === null || search === void 0 ? void 0 : search.split('&').forEach(function (pair) {
        var _a = __read(pair.split('='), 1), key = _a[0];
        delete newParams[key];
    });
    var newSearch = (0, request_utils_1.formDataToQuery)(newParams);
    newSearch = newSearch ? (search ? search + '&' : '') + newSearch : search;
    return "".concat(baseUrl, "?").concat(newSearch);
};
exports.extendURLParams = extendURLParams;
var jsonStringify = function (data, space) {
    // With plain JSON.stringify, we get an exception when a property is a BigInt. This has caused problems for some users,
    // see https://github.com/PostHog/posthog-js/issues/1440
    // To work around this, we convert BigInts to strings before stringifying the data. This is not ideal, as we lose
    // information that this was originally a number, but given ClickHouse doesn't support BigInts, the customer
    // would not be able to operate on these numerically anyway.
    return JSON.stringify(data, function (_, value) { return (typeof value === 'bigint' ? value.toString() : value); }, space);
};
exports.jsonStringify = jsonStringify;
var encodeToDataString = function (data) {
    return 'data=' + encodeURIComponent(typeof data === 'string' ? data : (0, exports.jsonStringify)(data));
};
var encodePostData = function (_a) {
    var data = _a.data, compression = _a.compression;
    if (!data) {
        return;
    }
    if (compression === types_1.Compression.GZipJS) {
        var gzipData = (0, fflate_1.gzipSync)((0, fflate_1.strToU8)((0, exports.jsonStringify)(data)), { mtime: 0 });
        var blob = new Blob([gzipData], { type: CONTENT_TYPE_PLAIN });
        return {
            contentType: CONTENT_TYPE_PLAIN,
            body: blob,
            estimatedSize: blob.size,
        };
    }
    if (compression === types_1.Compression.Base64) {
        var b64data = (0, encode_utils_1._base64Encode)((0, exports.jsonStringify)(data));
        var encodedBody = encodeToDataString(b64data);
        return {
            contentType: CONTENT_TYPE_FORM,
            body: encodedBody,
            estimatedSize: new Blob([encodedBody]).size,
        };
    }
    var jsonBody = (0, exports.jsonStringify)(data);
    return {
        contentType: CONTENT_TYPE_JSON,
        body: jsonBody,
        estimatedSize: new Blob([jsonBody]).size,
    };
};
var xhr = function (options) {
    var _a;
    var req = new globals_1.XMLHttpRequest();
    req.open(options.method || 'GET', options.url, true);
    var _b = (_a = encodePostData(options)) !== null && _a !== void 0 ? _a : {}, contentType = _b.contentType, body = _b.body;
    (0, utils_1.each)(options.headers, function (headerValue, headerName) {
        req.setRequestHeader(headerName, headerValue);
    });
    if (contentType) {
        req.setRequestHeader('Content-Type', contentType);
    }
    if (options.timeout) {
        req.timeout = options.timeout;
    }
    // send the ph_optout cookie
    // withCredentials cannot be modified until after calling .open on Android and Mobile Safari
    req.withCredentials = true;
    req.onreadystatechange = function () {
        var _a;
        // XMLHttpRequest.DONE == 4, except in safari 4
        if (req.readyState === 4) {
            var response = {
                statusCode: req.status,
                text: req.responseText,
            };
            if (req.status === 200) {
                try {
                    response.json = JSON.parse(req.responseText);
                }
                catch (_b) {
                    // logger.error(e)
                }
            }
            (_a = options.callback) === null || _a === void 0 ? void 0 : _a.call(options, response);
        }
    };
    req.send(body);
};
var _fetch = function (options) {
    var _a;
    var _b = (_a = encodePostData(options)) !== null && _a !== void 0 ? _a : {}, contentType = _b.contentType, body = _b.body, estimatedSize = _b.estimatedSize;
    // eslint-disable-next-line compat/compat
    var headers = new Headers();
    (0, utils_1.each)(options.headers, function (headerValue, headerName) {
        headers.append(headerName, headerValue);
    });
    if (contentType) {
        headers.append('Content-Type', contentType);
    }
    var url = options.url;
    var aborter = null;
    if (globals_1.AbortController) {
        var controller_1 = new globals_1.AbortController();
        aborter = {
            signal: controller_1.signal,
            timeout: setTimeout(function () { return controller_1.abort(); }, options.timeout),
        };
    }
    globals_1.fetch(url, __assign({ method: (options === null || options === void 0 ? void 0 : options.method) || 'GET', headers: headers, 
        // if body is greater than 64kb, then fetch with keepalive will error
        // see 8:10:5 at https://fetch.spec.whatwg.org/#http-network-or-cache-fetch,
        // but we do want to set keepalive sometimes as it can  help with success
        // when e.g. a page is being closed
        // so let's get the best of both worlds and only set keepalive for POST requests
        // where the body is less than 64kb
        // NB this is fetch keepalive and not http keepalive
        keepalive: options.method === 'POST' && (estimatedSize || 0) < KEEP_ALIVE_THRESHOLD, body: body, signal: aborter === null || aborter === void 0 ? void 0 : aborter.signal }, options.fetchOptions))
        .then(function (response) {
        return response.text().then(function (responseText) {
            var _a;
            var res = {
                statusCode: response.status,
                text: responseText,
            };
            if (response.status === 200) {
                try {
                    res.json = JSON.parse(responseText);
                }
                catch (e) {
                    logger_1.logger.error(e);
                }
            }
            (_a = options.callback) === null || _a === void 0 ? void 0 : _a.call(options, res);
        });
    })
        .catch(function (error) {
        var _a;
        logger_1.logger.error(error);
        (_a = options.callback) === null || _a === void 0 ? void 0 : _a.call(options, { statusCode: 0, text: error });
    })
        .finally(function () { return (aborter ? clearTimeout(aborter.timeout) : null); });
    return;
};
var _sendBeacon = function (options) {
    // beacon documentation https://w3c.github.io/beacon/
    // beacons format the message and use the type property
    var _a;
    var url = (0, exports.extendURLParams)(options.url, {
        beacon: '1',
    });
    try {
        var _b = (_a = encodePostData(options)) !== null && _a !== void 0 ? _a : {}, contentType = _b.contentType, body = _b.body;
        // sendBeacon requires a blob so we convert it
        var sendBeaconBody = typeof body === 'string' ? new Blob([body], { type: contentType }) : body;
        globals_1.navigator.sendBeacon(url, sendBeaconBody);
    }
    catch (_c) {
        // send beacon is a best-effort, fire-and-forget mechanism on page unload,
        // we don't want to throw errors here
    }
};
var AVAILABLE_TRANSPORTS = [];
// We add the transports in order of preference
if (globals_1.fetch) {
    AVAILABLE_TRANSPORTS.push({
        transport: 'fetch',
        method: _fetch,
    });
}
if (globals_1.XMLHttpRequest) {
    AVAILABLE_TRANSPORTS.push({
        transport: 'XHR',
        method: xhr,
    });
}
if (globals_1.navigator === null || globals_1.navigator === void 0 ? void 0 : globals_1.navigator.sendBeacon) {
    AVAILABLE_TRANSPORTS.push({
        transport: 'sendBeacon',
        method: _sendBeacon,
    });
}
// This is the entrypoint. It takes care of sanitizing the options and then calls the appropriate request method.
var request = function (_options) {
    var _a, _b, _c;
    // Clone the options so we don't modify the original object
    var options = __assign({}, _options);
    options.timeout = options.timeout || 60000;
    options.url = (0, exports.extendURLParams)(options.url, {
        _: new Date().getTime().toString(),
        ver: config_1.default.LIB_VERSION,
        compression: options.compression,
    });
    var transport = (_a = options.transport) !== null && _a !== void 0 ? _a : 'fetch';
    var transportMethod = (_c = (_b = (0, utils_1.find)(AVAILABLE_TRANSPORTS, function (t) { return t.transport === transport; })) === null || _b === void 0 ? void 0 : _b.method) !== null && _c !== void 0 ? _c : AVAILABLE_TRANSPORTS[0].method;
    if (!transportMethod) {
        throw new Error('No available transport method');
    }
    transportMethod(options);
};
exports.request = request;
//# sourceMappingURL=request.js.map