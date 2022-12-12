import { Primitive } from '@sentry/types';
import { MemoFunc } from './memo';
declare type ObjOrArray<T> = {
    [key: string]: T;
};
/**
 * Recursively normalizes the given object.
 *
 * - Creates a copy to prevent original input mutation
 * - Skips non-enumerable properties
 * - When stringifying, calls `toJSON` if implemented
 * - Removes circular references
 * - Translates non-serializable values (`undefined`/`NaN`/functions) to serializable format
 * - Translates known global objects/classes to a string representations
 * - Takes care of `Error` object serialization
 * - Optionally limits depth of final output
 * - Optionally limits number of properties/elements included in any single object/array
 *
 * @param input The object to be normalized.
 * @param depth The max depth to which to normalize the object. (Anything deeper stringified whole.)
 * @param maxProperties The max number of elements or properties to be included in any single array or
 * object in the normallized output..
 * @returns A normalized version of the object, or `"**non-serializable**"` if any errors are thrown during normalization.
 */
export declare function normalize(input: unknown, depth?: number, maxProperties?: number): any;
/** JSDoc */
export declare function normalizeToSize<T>(object: {
    [key: string]: any;
}, depth?: number, maxSize?: number): T;
/**
 * Visits a node to perform normalization on it
 *
 * @param key The key corresponding to the given node
 * @param value The node to be visited
 * @param depth Optional number indicating the maximum recursion depth
 * @param maxProperties Optional maximum number of properties/elements included in any single object/array
 * @param memo Optional Memo class handling decycling
 */
declare function visit(key: string, value: unknown, depth?: number, maxProperties?: number, memo?: MemoFunc): Primitive | ObjOrArray<unknown>;
export { visit as walk };
//# sourceMappingURL=normalize.d.ts.map