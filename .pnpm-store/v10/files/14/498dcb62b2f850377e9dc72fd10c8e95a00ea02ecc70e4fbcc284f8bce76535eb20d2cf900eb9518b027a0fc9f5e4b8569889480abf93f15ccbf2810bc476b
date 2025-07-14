import cookie from 'js-cookie';
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
export function tld(url) {
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
            cookie.set(cname, '1', opts);
            if (cookie.get(cname)) {
                cookie.remove(cname, opts);
                return domain;
            }
        }
        catch (_) {
            return;
        }
    }
}
//# sourceMappingURL=tld.js.map