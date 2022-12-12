/**
 * Copyright (c) 2020 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Creates a store API that uses cookies for each key/value pair.
 *
 * Status: BETA - unsupported, useful, needs testing
 */
;(function(window, document, store, _) {

    var C = _.cookies = {// still good enough for me
        maxAge: 60*60*24*365*10,
        suffix: ';path=/;sameSite=strict'
    };
    C.all = function() {
        if (!document.cookie) {
            return {};
        }
        var cookies = document.cookie.split('; '),
            all = {};
        for (var i=0, cookie, eq; i<cookies.length; i++) {
            cookie = cookies[i];
            eq = cookie.indexOf('=');
            all[cookie.substring(0, eq)] = decodeURIComponent(cookie.substring(eq+1));
        }
        return all;
    };
    C.read = function(key) {
        var match = document.cookie.match(new RegExp('(^| )'+key+'=([^;]+)'));
        return match ? decodeURIComponent(match[2]) : null;
    };
    C.write = function(key, value) {
        document.cookie = key+'='+encodeURIComponent(value)+';max-age='+C.maxAge+C.suffix;
    };
    C.remove = function(key) {
        document.cookie = key+'=;expires=Thu, 01 Jan 1970 00:00:01 GMT'+C.suffix;
    };
    C.area = {
        key: function(i) {
            var c = 0,
                state = C.all();
            for (var k in state) {
                if (state.hasOwnProperty(k) && i === c++) {
                    return k;
                }
            }
        },
        setItem: C.write,
        getItem: C.read,
        has: function(k) {
            return C.all().hasOwnProperty(k);
        },
        removeItem: C.remove,
        clear: function() {
            var state = C.all();
            for (var k in state) {
                C.remove(k);
            }
        }
    };
    Object.defineProperty(C.area, 'length', {
        get: function() {
            var ln = 0,
                state = C.all();
            for (var k in state) {
                if (state.hasOwnProperty(k)) {
                    ln++;
                }
            }
            return ln;
        }
    });

    // create the store api for this storage
    store.area('cookies', C.area);

})(window, document, window.store, window.store._);
