/**
 * Copyright (c) 2013 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * store.remainingSpace();// returns remainingSpace value (if browser supports it)
 * store.charsUsed();// returns length of all data when stringified
 * store.charsLeft([true]);// tests how many more chars we can fit (crash threat!)
 * store.charsTotal([true]);// charsUsed + charsLeft, duh.
 *
 * TODO: byte/string conversions
 *
 * Status: ALPHA - changing API *and* crash threats :)
 */
;(function(store, _) {

    function put(area, s) {
        try {
            area.setItem("__test__", s);
            return true;
        } catch (e) {}
    }

    _.fn('remainingSpace', function() {
        return this._area.remainingSpace;
    });
    _.fn('charsUsed', function() {
        return _.stringify(this.getAll()).length - 2;
    });
    _.fn('charsLeft', function(test) {
        if (this.isFake()){ return; }
        if (arguments.length === 0) {
            test = window.confirm('Calling store.charsLeft() may crash some browsers!');
        }
        if (test) {
            var s = 's ', add = s;
            // grow add for speed
            while (put(store._area, s)) {
                s += add;
                if (add.length < 50000) {
                    add = s;
                }
            }
            // shrink add for accuracy
            while (add.length > 2) {
                s = s.substring(0, s.length - (add.length/2));
                while (put(store._area, s)) {
                    s += add;
                }
                add = add.substring(add.length/2);
            }
            _.remove(store._area, "__test__");
            return s.length + 8;
        }
    });
    _.fn('charsTotal', function(test) {
        return store.charsUsed() + store.charsLeft(test);
    });

})(window.store, window.store._);