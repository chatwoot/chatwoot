/**
 * Copyright (c) 2013 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * If fake (non-persistent) storage for users stuck in the dark ages 
 * does not satisfy you, this will replace it with the a reasonable imitator for their
 * pathetic, incompetent browser.  Note that the session replacement here is potentially
 * insecure as it uses window.name without any fancy protections.
 *
 * Status: BETA - unsupported, useful, needs testing & refining
 */
;(function(window, document, store, _) {

    function addUpdateFn(area, name, update) {
        var old = area[name];
        area[name] = function() {
            var ret = old.apply(this, arguments);
            update.apply(this, arguments);
            return ret;
        };
    }
    function create(name, items, update) {
        var length = 0;
        for (var k in items) {
            if (items.hasOwnProperty(k)) {
                length++;
            }
        }
        var area = _.inherit(_.storageAPI, { items:items, length:length, name:name });
        if (update) {
            addUpdateFn(area, 'setItem', update);
            addUpdateFn(area, 'removeItem', update);
        }
        return area;
    }

    if (store.isFake()) {
        var area;

        if (document.documentElement.addBehavior) {// IE userData
            var el = document.createElement('div'),
                sn = 'localStorage',
                body = document.body,
                wrap = function wrap(fn) {
                    return function() {
                        body.appendChild(el);
                        el.addBehavior('#default#userData');
                        el.load(sn);
                        var ret = fn.apply(store._area, arguments);
                        el.save(sn);
                        body.removeChild(el);
                        return ret;
                    };
                },
                has = function has(key){
                    return el.getAttribute(key) !== null;
                },
                UserDataStorage = function UserDataStorage(){};

            UserDataStorage.prototype = {
                length: (wrap(function(){
                    return el.XMLDocument.documentElement.attributes.length;
                }))(),
                has: wrap(has),
                key: wrap(function(i) {
                    return el.XMLDocument.documentElement.attributes[i];
                }),
                setItem: wrap(function(k, v) {
                    if (!has(k)) {
                        this.length++;
                    }
                    el.setAttribute(k, v);
                }),
                removeItem: wrap(function(k) {
                    if (has(k)) {
                        el.removeAttribute(k);
                        this.length--;
                    }
                }),
                getItem: wrap(function(k){ return el.getAttribute(k); }),
                clear: wrap(function() {
                    var all = el.XMLDocument.documentElement.attributes;
                    for (var i=0, a; !!(a = all[i]); i++) {
                        el.removeAttribute(a.name);
                    }
                    this.length = 0;
                })
            };
            area = new UserDataStorage();

        } else if ('globalStorage' in window && window.globalStorage) {// FF globalStorage
            area = create('global', window.globalStorage[window.location.hostname]);

        } else {// cookie
            var date = new Date(),
                key = 'store.local',
                items = {},
                cookies = document.cookie.split(';');
            date.setTime(date.getTime()+(5*365*24*60*60*1000));//5 years out
            date = date.toGMTString();
            for (var i=0,m=cookies.length; i<m; i++) {
                var c = cookies[i];
                while (c.charAt(0) === ' ') {
                    c = c.substring(1, c.length);
                }
                if (c.indexOf(key) === 0) {
                    items = JSON.parse(c.substring(key.length+1));
                }
            }
            area = create('cookie', items, function() {
                document.cookie = key+"="+JSON.stringify(this.items)+"; expires="+date+"; path=/";
            });
        }

        // replace local's fake storage
        store._area = _.areas.local = area;
    }

    if (store.session.isFake()) {
        var sItems = window.name ? JSON.parse(window.name)[document.domain]||{} : {};
        store.session._area = _.areas.session =
            create('windowName', sItems, function() {
                var o = {};
                o[document.domain] = this.items;
                window.name = JSON.stringify(o);
            });
    }

})(window, document, window.store, window.store._);
