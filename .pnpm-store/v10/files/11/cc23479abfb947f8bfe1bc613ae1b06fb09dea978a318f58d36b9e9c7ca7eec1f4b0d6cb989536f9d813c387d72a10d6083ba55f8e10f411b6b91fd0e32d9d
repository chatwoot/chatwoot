function findScript(src) {
    var scripts = Array.prototype.slice.call(window.document.querySelectorAll('script'));
    return scripts.find(function (s) { return s.src === src; });
}
export function loadScript(src, attributes) {
    var found = findScript(src);
    if (found !== undefined) {
        var status_1 = found === null || found === void 0 ? void 0 : found.getAttribute('status');
        if (status_1 === 'loaded') {
            return Promise.resolve(found);
        }
        if (status_1 === 'loading') {
            return new Promise(function (resolve, reject) {
                found.addEventListener('load', function () { return resolve(found); });
                found.addEventListener('error', function (err) { return reject(err); });
            });
        }
    }
    return new Promise(function (resolve, reject) {
        var _a;
        var script = window.document.createElement('script');
        script.type = 'text/javascript';
        script.src = src;
        script.async = true;
        script.setAttribute('status', 'loading');
        for (var _i = 0, _b = Object.entries(attributes !== null && attributes !== void 0 ? attributes : {}); _i < _b.length; _i++) {
            var _c = _b[_i], k = _c[0], v = _c[1];
            script.setAttribute(k, v);
        }
        script.onload = function () {
            script.onerror = script.onload = null;
            script.setAttribute('status', 'loaded');
            resolve(script);
        };
        script.onerror = function () {
            script.onerror = script.onload = null;
            script.setAttribute('status', 'error');
            reject(new Error("Failed to load ".concat(src)));
        };
        var tag = window.document.getElementsByTagName('script')[0];
        (_a = tag.parentElement) === null || _a === void 0 ? void 0 : _a.insertBefore(script, tag);
    });
}
export function unloadScript(src) {
    var found = findScript(src);
    if (found !== undefined) {
        found.remove();
    }
    return Promise.resolve();
}
//# sourceMappingURL=load-script.js.map