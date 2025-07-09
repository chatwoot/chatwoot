// Code derived from https://github.com/jonschlinkert/is-plain-object/blob/master/is-plain-object.js
function isObject(o) {
    return Object.prototype.toString.call(o) === '[object Object]';
}
export function isPlainObject(o) {
    if (isObject(o) === false)
        return false;
    // If has modified constructor
    var ctor = o.constructor;
    if (ctor === undefined)
        return true;
    // If has modified prototype
    var prot = ctor.prototype;
    if (isObject(prot) === false)
        return false;
    // If constructor does not have an Object-specific method
    // eslint-disable-next-line no-prototype-builtins
    if (prot.hasOwnProperty('isPrototypeOf') === false) {
        return false;
    }
    // Most likely a plain Object
    return true;
}
//# sourceMappingURL=is-plain-object.js.map