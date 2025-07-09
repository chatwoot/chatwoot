"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isThenable = void 0;
/**
 *  Check if  thenable
 *  (instanceof Promise doesn't respect realms)
 */
var isThenable = function (value) {
    return typeof value === 'object' &&
        value !== null &&
        'then' in value &&
        typeof value.then === 'function';
};
exports.isThenable = isThenable;
//# sourceMappingURL=is-thenable.js.map