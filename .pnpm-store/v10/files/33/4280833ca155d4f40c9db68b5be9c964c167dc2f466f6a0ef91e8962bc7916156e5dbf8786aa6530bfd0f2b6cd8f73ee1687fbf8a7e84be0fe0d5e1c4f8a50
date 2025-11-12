"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isLocalhost = exports._getHashParam = exports.maskQueryParams = exports.getQueryParam = exports.formDataToQuery = exports.convertToURL = void 0;
var _1 = require("./");
var core_1 = require("@posthog/core");
var logger_1 = require("./logger");
var globals_1 = require("./globals");
var localDomains = ['localhost', '127.0.0.1'];
/**
 * IE11 doesn't support `new URL`
 * so we can create an anchor element and use that to parse the URL
 * there's a lot of overlap between HTMLHyperlinkElementUtils and URL
 * meaning useful properties like `pathname` are available on both
 */
var convertToURL = function (url) {
    var location = globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.createElement('a');
    if ((0, core_1.isUndefined)(location)) {
        return null;
    }
    location.href = url;
    return location;
};
exports.convertToURL = convertToURL;
var formDataToQuery = function (formdata, arg_separator) {
    if (arg_separator === void 0) { arg_separator = '&'; }
    var use_val;
    var use_key;
    var tph_arr = [];
    (0, _1.each)(formdata, function (val, key) {
        // the key might be literally the string undefined for e.g. if {undefined: 'something'}
        if ((0, core_1.isUndefined)(val) || (0, core_1.isUndefined)(key) || key === 'undefined') {
            return;
        }
        use_val = encodeURIComponent((0, core_1.isFile)(val) ? val.name : val.toString());
        use_key = encodeURIComponent(key);
        tph_arr[tph_arr.length] = use_key + '=' + use_val;
    });
    return tph_arr.join(arg_separator);
};
exports.formDataToQuery = formDataToQuery;
// NOTE: Once we get rid of IE11/op_mini we can start using URLSearchParams
var getQueryParam = function (url, param) {
    var withoutHash = url.split('#')[0] || '';
    // Split only on the first ? to sort problem out for those with multiple ?s
    // and then remove them
    var queryParams = withoutHash.split(/\?(.*)/)[1] || '';
    var cleanedQueryParams = queryParams.replace(/^\?+/g, '');
    var queryParts = cleanedQueryParams.split('&');
    var keyValuePair;
    for (var i = 0; i < queryParts.length; i++) {
        var parts = queryParts[i].split('=');
        if (parts[0] === param) {
            keyValuePair = parts;
            break;
        }
    }
    if (!(0, core_1.isArray)(keyValuePair) || keyValuePair.length < 2) {
        return '';
    }
    else {
        var result = keyValuePair[1];
        try {
            result = decodeURIComponent(result);
        }
        catch (_a) {
            logger_1.logger.error('Skipping decoding for malformed query param: ' + result);
        }
        return result.replace(/\+/g, ' ');
    }
};
exports.getQueryParam = getQueryParam;
// replace any query params in the url with the provided mask value. Tries to keep the URL as instant as possible,
// including preserving malformed text in most cases
var maskQueryParams = function (url, maskedParams, mask) {
    if (!url || !maskedParams || !maskedParams.length) {
        return url;
    }
    var splitHash = url.split('#');
    var withoutHash = splitHash[0] || '';
    var hash = splitHash[1];
    var splitQuery = withoutHash.split('?');
    var queryString = splitQuery[1];
    var urlWithoutQueryAndHash = splitQuery[0];
    var queryParts = (queryString || '').split('&');
    // use an array of strings rather than an object to preserve ordering and duplicates
    var paramStrings = [];
    for (var i = 0; i < queryParts.length; i++) {
        var keyValuePair = queryParts[i].split('=');
        if (!(0, core_1.isArray)(keyValuePair)) {
            continue;
        }
        else if (maskedParams.includes(keyValuePair[0])) {
            paramStrings.push(keyValuePair[0] + '=' + mask);
        }
        else {
            paramStrings.push(queryParts[i]);
        }
    }
    var result = urlWithoutQueryAndHash;
    if (queryString != null) {
        result += '?' + paramStrings.join('&');
    }
    if (hash != null) {
        result += '#' + hash;
    }
    return result;
};
exports.maskQueryParams = maskQueryParams;
var _getHashParam = function (hash, param) {
    var matches = hash.match(new RegExp(param + '=([^&]*)'));
    return matches ? matches[1] : null;
};
exports._getHashParam = _getHashParam;
var isLocalhost = function () {
    return localDomains.includes(location.hostname);
};
exports.isLocalhost = isLocalhost;
//# sourceMappingURL=request-utils.js.map