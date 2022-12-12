/**
 * Copyright (c) 2013 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Bind handlers to quota errors:
 *   store.quota(function(e, area, key, str) {
 *      console.log(e, area, key, str);
 *   });
 * If a handler returns true other handlers are not called and
 * the error is suppressed.
 *
 * Think quota errors will never happen to you? Think again:
 * http://spin.atomicobject.com/2013/01/23/ios-private-browsing-localstorage/
 * (this affects sessionStorage too)
 *
 * Status: ALPHA - API could use unbind feature
 */
;(function(store, _) {

    store.quota = function(fn) {
        store.quota.fns.push(fn);
    };
    store.quota.fns = [];

    var _set = _.set;
    _.set = function(area, key, str) {
        try {
            _set.apply(this, arguments);
        } catch (e) {
            if (e.name === 'QUOTA_EXCEEDED_ERR' ||
                e.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
                var fns = store.quota.fns;
                for (var i=0,m=fns.length; i<m; i++) {
                    if (true === fns[i].call(this, e, area, key, str)) {
                        return;
                    }
                }
            }
            throw e;
        }
    };

})(window.store, window.store._);