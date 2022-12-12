/**
 * Copyright (c) 2015 ESHA Research
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Store nothing when storage is not supported.
 *
 * Status: ALPHA - due to being of doubtful propriety
 */
;(function(_) {

    var _set = _.set;
    _.set = function(area) {
        return area.name === 'fake' ? undefined : _set.apply(this, arguments);
    };

})(window.store._);
