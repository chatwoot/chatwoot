/**
 * Copyright (c) 2017 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Allows retrieval of values from within a stored object.
 *
 *   store.set('foo', { is: { not: { quite: false }}});
 *   console.log(store.get('foo.is.not.quite'));// logs false
 *
 * Status: ALPHA - currently only supports get, inefficient, uses eval
 */
;(function(_) {

    // save original core accessor
    var _get = _.get;
    // replace with enhanced version
    _.get = function(area, key, kid) {
        var s = _get(area, key);
        if (s == null) {
            var parts = _.split(key);
            if (parts) {
                key = parts[0];
                kid = kid ? parts[1] + '.' + kid : parts[1];
                return _.get(area, parts[0], kid);
            }
        } else if (kid) {
            var val = _.parse(s);
            /*jshint evil:true */
            val = eval("val."+kid);
            s = _.stringify(val);
        }
        return s;
    };

    // expose internals on the underscore to allow extensibility
    _.split = function(key) {
        var dot = key.lastIndexOf('.');
        if (dot > 0) {
            var kid = key.substring(dot+1, key.length);
            key = key.substring(0, dot);
            return [key, kid];
        }
    };

})(window.store._);
