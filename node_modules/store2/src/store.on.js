/**
 * Copyright (c) 2013 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Makes it easy to watch for storage events by enhancing the events and
 * allowing binding to particular keys and/or namespaces.
 *
 * // listen to particular key storage events (yes, this is namespace sensitive)
 * store.on('foo', function listenToFoo(e){ console.log('foo was changed:', e); });
 * store.off('foo', listenToFoo);
 *
 * // listen to all storage events (also namespace sensitive)
 * store.on(function storageEvent(e){ console.log('web storage:', e); });
 * store.off(storageEvent);
 * 
 * Status: BETA - useful, if you aren't using IE8 or worse
 */
;(function(window, _) {

    _.on = function(key, fn) {
        if (!fn) { fn = key; key = ''; }// no key === all keys
        var s = this,
            listener = function(e) {
            var k = s._out(e.key);// undefined if key is not in the namespace
            if ((k && (k === key ||// match key if listener has one
                       (!key && k !== '_-bad-_'))) &&// match catch-all, except internal test
                (!e.storageArea || e.storageArea === s._area)) {// match area, if available
                return fn.call(s, _.event.call(s, k, e));
            }
        };
        window.addEventListener("storage", fn[key+'-listener']=listener, false);
        return this;
    };

    _.off = function(key, fn) {
        if (!fn) { fn = key; key = ''; }// no key === all keys
        window.removeEventListener("storage", fn[key+'-listener']);
        return this;
    };

    _.once = function(key, fn) {
        if (!fn) { fn = key; key = ''; }
        var s = this, listener;
        return s.on(key, listener = function() {
            s.off(key, listener);
            return fn.apply(this, arguments);
        });
    };

    _.event = function(k, e) {
        var event = {
            key: k,
            namespace: this.namespace(),
            newValue: _.parse(e.newValue),
            oldValue: _.parse(e.oldValue),
            url: e.url || e.uri,
            storageArea: e.storageArea,
            source: e.source,
            timeStamp: e.timeStamp,
            originalEvent: e
        };
        if (_.cache) {
            var min = _.expires(e.newValue || e.oldValue);
            if (min) {
                event.expires = _.when(min);
            }
        }
        return event;
    };

    // store2 policy is to not throw errors on old browsers
    var old = !window.addEventListener ? function(){} : null;
    _.fn('on', old || _.on);
    _.fn('off', old || _.off);
    _.fn('once', old || _.once);

})(window, window.store._);
