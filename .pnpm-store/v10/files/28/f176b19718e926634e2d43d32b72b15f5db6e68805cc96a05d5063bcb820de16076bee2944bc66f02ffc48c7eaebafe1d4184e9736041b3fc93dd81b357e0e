import { knownUnsafeEditableEvent } from "../types.mjs";
import { includes } from "./string-utils.mjs";
const nativeIsArray = Array.isArray;
const ObjProto = Object.prototype;
const type_utils_hasOwnProperty = ObjProto.hasOwnProperty;
const type_utils_toString = ObjProto.toString;
const isArray = nativeIsArray || function(obj) {
    return '[object Array]' === type_utils_toString.call(obj);
};
const isFunction = (x)=>'function' == typeof x;
const isNativeFunction = (x)=>isFunction(x) && -1 !== x.toString().indexOf('[native code]');
const isObject = (x)=>x === Object(x) && !isArray(x);
const isEmptyObject = (x)=>{
    if (isObject(x)) {
        for(const key in x)if (type_utils_hasOwnProperty.call(x, key)) return false;
        return true;
    }
    return false;
};
const isUndefined = (x)=>void 0 === x;
const isString = (x)=>'[object String]' == type_utils_toString.call(x);
const isEmptyString = (x)=>isString(x) && 0 === x.trim().length;
const isNull = (x)=>null === x;
const isNullish = (x)=>isUndefined(x) || isNull(x);
const isNumber = (x)=>'[object Number]' == type_utils_toString.call(x);
const isBoolean = (x)=>'[object Boolean]' === type_utils_toString.call(x);
const isFormData = (x)=>x instanceof FormData;
const isFile = (x)=>x instanceof File;
const isError = (x)=>x instanceof Error;
const isKnownUnsafeEditableEvent = (x)=>includes(knownUnsafeEditableEvent, x);
export { type_utils_hasOwnProperty as hasOwnProperty, isArray, isBoolean, isEmptyObject, isEmptyString, isError, isFile, isFormData, isFunction, isKnownUnsafeEditableEvent, isNativeFunction, isNull, isNullish, isNumber, isObject, isString, isUndefined };
