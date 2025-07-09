"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.tld = void 0;
var tslib_1 = require("tslib");
var js_cookie_1 = tslib_1.__importDefault(require("js-cookie"));
/**
 * Levels returns all levels of the given url.
 *
 * @param {string} url
 * @return {Array}
 * @api public
 */
function levels(url) {
    var host = url.hostname;
    var parts = host.split('.');
    var last = parts[parts.length - 1];
    var levels = [];
    // Ip address.
    if (parts.length === 4 && parseInt(last, 10) > 0) {
        return levels;
    }
    // Localhost.
    if (parts.length <= 1) {
        return levels;
    }
    // Create levels.
    for (var i = parts.length - 2; i >= 0; --i) {
        levels.push(parts.slice(i).join('.'));
    }
    return levels;
}
function parseUrl(url) {
    try {
        return new URL(url);
    }
    catch (_a) {
        return;
    }
}
function tld(url) {
    var parsedUrl = parseUrl(url);
    if (!parsedUrl)
        return;
    var lvls = levels(parsedUrl);
    // Lookup the real top level one.
    for (var i = 0; i < lvls.length; ++i) {
        var cname = '__tld__';
        var domain = lvls[i];
        var opts = { domain: '.' + domain };
        try {
            // cookie access throw an error if the library is ran inside a sandboxed environment (e.g. sandboxed iframe)
            js_cookie_1.default.set(cname, '1', opts);
            if (js_cookie_1.default.get(cname)) {
                js_cookie_1.default.remove(cname, opts);
                return domain;
            }
        }
        catch (_) {
            return;
        }
    }
}
exports.tld = tld;
//# sourceMappingURL=tld.js.map