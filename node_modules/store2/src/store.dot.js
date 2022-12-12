/**
 * Copyright (c) 2017 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Adds getters and setters for existing keys (and newly set() ones) to enable dot access to stored properties.
 *
 *   store.dot('foo','bar');// makes store aware of keys (could also do store.set('foo',''))
 *   store.foo = { is: true };// == store.set('foo', { is: true });
 *   console.log(store.foo.is);// logs 'true'
 * 
 * This will not create accessors that conflict with existing properties of the store object.
 *
 * Status: ALPHA - good, but ```store.foo.is=false``` won't persist while looking like it would 
 */
;(function(_, Object, Array) {

    // expose internals on the underscore to allow extensibility
    _.dot = function(key) {
        var keys = !key ? this.keys() :
            Array.isArray(key) ? key :
            Array.prototype.slice.call(arguments),
            target = this;
        keys.forEach(function(key) {
            _.dot.define(target, key);
        });
        return this;
    };
    _.dot.define = function(target, key) {
        if (!(key in target)) {
            Object.defineProperty(target, key, {
                enumerable: true,
                get: function(){ return this.get(key); },
                set: function(value){ this.set(key, value); }
            });
        }
    };

    // add function(s) to the store interface
    _.fn('dot', _.dot);

})(window.store._, window.Object, window.Array);
