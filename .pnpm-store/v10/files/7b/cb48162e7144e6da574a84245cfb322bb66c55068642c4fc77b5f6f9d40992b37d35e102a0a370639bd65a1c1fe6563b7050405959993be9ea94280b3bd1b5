/**
 *  Check if  thenable
 *  (instanceof Promise doesn't respect realms)
 */
export var isThenable = function (value) {
    return typeof value === 'object' &&
        value !== null &&
        'then' in value &&
        typeof value.then === 'function';
};
//# sourceMappingURL=is-thenable.js.map