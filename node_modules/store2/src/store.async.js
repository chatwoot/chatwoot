/**
 * Copyright (c) 2019 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Adds an 'async' duplicate on all store APIs that
 * performs storage-related operations asynchronously and returns
 * a promise.
 *
 * Status: BETA - works great, but lacks justification for existence
 */
;(function(window, _) {

    var dontPromisify = ['async', 'area', 'namespace', 'isFake', 'toString'];
    _.promisify = function(api) {
        var async = api.async = _.Store(api._id, api._area, api._ns);
        async._async = true;
        Object.keys(api).forEach(function(name) {
            if (name.charAt(0) !== '_' && dontPromisify.indexOf(name) < 0) {
                var fn = api[name];
                if (typeof fn === "function") {
                    async[name] = _.promiseFn(name, fn, api);
                }
            }
        });
        return async;
    };
    _.promiseFn = function(name, fn, self) {
        return function promised() {
            var args = arguments;
            return new Promise(function(resolve, reject) {
                setTimeout(function() {
                    try {
                        resolve(fn.apply(self, args));
                    } catch (e) {
                        reject(e);
                    }
                }, 0);
            });
        };
    };

    // promisify existing apis
    for (var apiName in _.apis) {
        _.promisify(_.apis[apiName]);
    }
    // ensure future apis are promisified
    Object.defineProperty(_.storeAPI, 'async', {
        enumerable: true,
        configurable: true,
        get: function() {
            var async = _.promisify(this);
            // overwrite getter to avoid re-promisifying
            Object.defineProperty(this, 'async', {
                enumerable: true,
                value: async
            });
            return async;
        }
    });

})(window, window.store._);
