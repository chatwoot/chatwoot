/**
 * Copyright (c) 2017 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Adds shortcut for safely applying all available Array functions to stored values. If there is no
 * value, the functions will act as if upon an empty one. If there is a non, array value, it is put
 * into an array before the function is applied. If the function results in an empty array, the
 * key/value is removed from the storage, otherwise the array is restored.
 *
 *   store.push('array', 'a', 1, true);// == store.set('array', (store.get('array')||[]).push('a', 1, true]));
 *   store.indexOf('array', true);// === store.get('array').indexOf(true)
 * 
 * This will add all functions of Array.prototype that are specific to the Array interface and have no
 * conflict with existing store functions.
 *
 * Status: BETA - useful, but adds more functions than reasonable
 */
;(function(_, Array) {

    // expose internals on the underscore to allow extensibility
    _.array = function(fnName, key, args) {
        var value = this.get(key, []),
            array = Array.isArray(value) ? value : [value],
            ret = array[fnName].apply(array, args);
        if (array.length > 0) {
            this.set(key, array.length > 1 ? array : array[0]);
        } else {
            this.remove(key);
        }
        return ret;
    };
    _.arrayFn = function(fnName) {
        return function(key) {
            return this.array(fnName, key,
                arguments.length > 1 ? Array.prototype.slice.call(arguments, 1) : null);
        };
    };

    // add function(s) to the store interface
    _.fn('array', _.array);
    Object.getOwnPropertyNames(Array.prototype).forEach(function(name) {
        // add Array interface functions w/o existing conflicts
        if (typeof Array.prototype[name] === "function") {
            if (!(name in _.storeAPI)) {
                _.fn(name, _.array[name] = _.arrayFn(name));
            }
        }
    });

})(window.store._, window.Array);
