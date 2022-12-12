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
 * // listen to all storage events
 * store.on(function storageEvent(e){ console.log('web storage:', e); });
 * store.off(storageEvent);
 * 
 * Status: ALPHA - useful, if you don't mind incomplete browser support for events
 */
;(function(window, document, _) {
    _.fn('on', function(key, fn) {
        if (!fn) { fn = key; key = ''; }// shift args when needed
        var s = this,
            bound,
            id = _.id(this._area);
        if (window.addEventListener) {
            window.addEventListener("storage", bound = function(e) {
                var k = s._out(e.key);
                if (k && (!key || k === key)) {// must match key if listener has one
                    var eid = _.id(e.storageArea);
                    if (!eid || id === eid) {// must match area, if event has a known one
                        return fn.call(s, _.event(k, s, e));
                    }
                }
            }, false);
        } else {
            document.attachEvent("onstorage", bound = function() {
                return fn.call(s, window.event);
            });
        }
        fn['_'+key+'listener'] = bound;
        return s;
    });
    _.fn('off', function(key, fn) {
        if (!fn) { fn = key; key = ''; }// shift args when needed
        var bound = fn['_'+key+'listener'];
        if (window.removeEventListener) {
            window.removeEventListener("storage", bound);
        } else {
            document.detachEvent("onstorage", bound);
        }
        return this;
    });
    _.event = function(k, s, e) {
        var event = {
            key: k,
            namespace: s.namespace(),
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
    _.id = function(area) {
        for (var id in _.areas) {
            if (area === _.areas[id]) {
                return id;
            }
        }
    };
})(window, document, window.store._);