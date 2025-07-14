/**
 * Commonly shared utility functions between official FormKit packages.
 *
 * You can add this package by using `npm install @formkit/utils` or `yarn add @formkit/utils`.
 *
 * @packageDocumentation
 */
/**
 * Generates a random string.
 *
 * @example
 *
 * ```javascript
 * import { token } from '@formkit/utils'
 *
 * const tk = token()
 * // 'jkbyqnphqm'
 * ```
 *
 * @returns string
 *
 * @public
 */
declare function token(): string;
/**
 * Creates a new set of the specified type and uses the values from an Array or
 * an existing Set.
 *
 * @example
 *
 * ```javascript
 * import { setify } from '@formkit/utils'
 *
 * const tk = setify(['a', 'b'])
 * // Set(2) {'a', 'b'}
 * ```
 *
 * @param items - An array or a Set.
 *
 * @returns `Set<T>`
 *
 * @public
 */
declare function setify<T>(items: Set<T> | T[] | null | undefined): Set<T>;
/**
 * Given 2 arrays, return them as a combined array with no duplicates.
 *
 * @param arr1 - First array.
 * @param arr2 - Second array.
 *
 * @returns `any[]`
 *
 * @public
 */
declare function dedupe<T extends any[] | Set<any>, X extends any[] | Set<any>>(arr1: T, arr2?: X): any[];
/**
 * Checks if the given property exists on the given object.
 *
 * @param obj - An object to check.
 * @param property - The property to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function has(obj: {
    [index: string]: any;
    [index: number]: any;
}, property: string | symbol | number): boolean;
/**
 * Compare two values for equality, optionally at depth.
 *
 * @param valA - First value.
 * @param valB - Second value.
 * @param deep - If it will compare deeply if it's an object.
 * @param explicit - An array of keys to explicity check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function eq(valA: any, // eslint-disable-line
valB: any, // eslint-disable-line
deep?: boolean, explicit?: string[]): boolean;
/**
 * A regular expression to test for a valid date string.
 * @param x - A RegExp to compare.
 * @param y - A RegExp to compare.
 * @public
 */
declare function eqRegExp(x: RegExp, y: RegExp): boolean;
/**
 * Determines if a value is empty or not.
 *
 * @param value - The value to check if it's empty.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function empty(value: any): boolean;
/**
 * Escape a string for use in regular expressions.
 *
 * @param string - String to be escaped.
 *
 * @returns `string`
 *
 * @public
 */
declare function escapeExp(string: string): string;
/**
 * The date token strings that can be used for date formatting.
 *
 * @public
 */
type FormKitDateTokens = 'MM' | 'M' | 'DD' | 'D' | 'YYYY' | 'YY';
/**
 * Given a string date format, return a regex to match against.
 *
 * @param format - String to be transformed to RegExp.
 *
 * @example
 *
 * ```javascript
 * regexForFormat('MM') // returns '(0[1-9]|1[012])'
 * ```
 *
 * @returns `RegExp`
 *
 * @public
 */
declare function regexForFormat(format: string): RegExp;
/**
 * Given a FormKit input type, returns the correct lowerCased() type.
 *
 * @param type - String to return to check for correct type
 *
 * @returns `'list' | 'group' | 'input'`
 *
 * @public
 */
declare function nodeType(type: string): 'list' | 'group' | 'input';
/**
 * Determines if an object is an object.
 *
 * @param o - The value to be checked.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isRecord(o: unknown): o is Record<PropertyKey, unknown>;
/**
 * Checks if an object is a simple array or record.
 *
 * @param o - Value to be checked.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isObject(o: unknown): o is Record<PropertyKey, unknown> | unknown[];
/**
 * Attempts to determine if an object is a POJO (Plain Old JavaScript Object).
 * Mostly lifted from is-plain-object: https://github.com/jonschlinkert/is-plain-object
 * Copyright (c) 2014-2017, Jon Schlinkert.
 *
 * @param o - The value to be checked.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isPojo(o: any): o is Record<string, any>;
/**
 * Recursively merge data from additional into original returning a new object.
 *
 * @param original - The original array.
 * @param additional - The array to merge.
 * @param extendArrays - If it will extend/concatenate array values instead of
 * replacing them.
 * @param ignoreUndefined - If it will preserve values from the original object
 * even if the additional object has those values set to undefined.
 *
 * @returns `Record<string, any> | string | null`
 *
 * @public
 *
 */
declare const extend: (original: Record<string, any>, additional: Record<string, any> | string | null, extendArrays?: boolean, ignoreUndefined?: boolean) => Record<string, any> | string | null;
/**
 * Determine if the given string is fully quoted.
 *
 * @example
 *
 * ```javascript
 * hello - false
 * "hello" - true
 * 'world' - true
 * "hello"=="world" - false
 * "hello'this'" - false
 * "hello"'there' - false
 * "hello""there" - false
 * 'hello === world' - true
 * ```
 *
 * @param str - The string to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isQuotedString(str: string): boolean;
/**
 * Remove extra escape characters.
 *
 * @param str - String to remove extra escape characters from.
 *
 * @returns `string`
 *
 * @public
 */
declare function rmEscapes(str: string): string;
/**
 * Performs a recursive `Object.assign`-like operation.
 *
 * @param a - An object to be assigned.
 * @param b - An object to get values from.
 *
 * @returns `A & B`
 *
 * @public
 */
declare function assignDeep<A extends Record<PropertyKey, any>, B extends Record<PropertyKey, any>>(a: A, b: B): A & B;
/**
 * Filters out values from an object that should not be considered "props" of
 * a core node, like "value" and "name".
 *
 * @param sets - The arrays to get values filtered out of.
 *
 * @returns `Record<string, any>`
 *
 * @public
 */
declare function nodeProps(...sets: Array<Record<string, any>>): Record<string, any>;
/**
 * Parse a string for comma-separated arguments.
 *
 * @param str - String to parse arguments from.
 *
 * @returns `string[]`
 *
 * @public
 */
declare function parseArgs(str: string): string[];
/**
 * Return a new (shallow) object with any desired props removed.
 *
 * @param obj - The starting object.
 * @param toRemove - The array of properties to remove. Accepts strings or
 * regular expressions.
 *
 * @returns `Record<string, any>`
 *
 * @public
 */
declare function except(obj: Record<string, any>, toRemove: Array<string | RegExp>): Record<string, any>;
/**
 * Extracts a set of keys from a given object. Importantly, this will extract
 * values even if they are not set on the original object — they will just have
 * an undefined value.
 *
 * @param obj - The object to get values from.
 * @param include - The array of items to get.
 *
 * @returns `Record<string, any>`
 *
 * @public
 */
declare function only(obj: Record<string, any>, include: Array<string | RegExp>): Record<string, any>;
/**
 * This converts kebab-case to camelCase. It ONLY converts from kebab to camel.
 *
 * @param str - String to be camel cased.
 *
 * @returns `string`
 *
 * @public
 */
declare function camel(str: string): string;
/**
 * This converts camel-case to kebab case. It ONLY converts from camel to kebab.
 *
 * @param str - String to be kebabed.
 *
 * @returns `string`
 *
 * @public
 */
declare function kebab(str: string): string;
/**
 * Shallowly clones the given object.
 *
 * @param obj - Object to be shallowly cloned.
 * @param explicit - The array of keys to be explicity cloned.
 *
 * @returns `T`
 *
 * @public
 */
declare function shallowClone<T>(obj: T, explicit?: string[]): T;
/**
 * Perform a recursive clone on a given object. Only intended to be used
 * for simple objects like arrays and POJOs.
 *
 * @param obj - Object to be cloned.
 * @param explicit - Array of items to be explicity cloned.
 *
 * @returns `T`
 *
 * @public
 */
declare function clone<T extends Record<string, unknown> | unknown[] | null>(obj: T, explicit?: string[]): T;
/**
 * Clones anything. If the item is scalar, no worries, it passes it back. If it
 * is an object, it performs a (fast/loose) clone operation.
 *
 * @param obj - The value to be cloned.
 *
 * @returns `T`
 *
 * @public
 */
declare function cloneAny<T>(obj: T): T;
/**
 * Get a specific value via dot notation.
 *
 * @param obj - An object to fetch data from.
 * @param addr - An "address" in dot notation.
 *
 * @returns `unknown`
 *
 * @public
 */
declare function getAt(obj: any, addr: string): unknown;
/**
 * Determines if the value of a prop that is either present (true) or not
 * present (undefined). For example, the prop disabled should disable
 * by just existing, but what if it is set to the string "false" — then it
 * should not be disabled.
 *
 * @param value - Value to check for undefined.
 *
 * @returns `true | undefined`
 *
 * @public
 */
declare function undefine(value: unknown): true | undefined;
/**
 * Defines an object as an initial value.
 *
 * @param obj - Object to be added an initial value.
 *
 * @returns `T & { __init?: true }`
 *
 * @public
 */
declare function init<T extends object>(obj: T): T & {
    __init?: true;
};
/**
 * Turn any string into a URL/DOM-safe string.
 *
 * @param str - String to be slugified to a URL-safe string.
 *
 * @returns `string`
 *
 * @public
 */
declare function slugify(str: string): string;
/**
 * Spreads an object or an array, otherwise returns the same value.
 *
 * @param obj - The object to be spread.
 * @param explicit - The array of items to be explicity spread.
 *
 * @returns `T`
 *
 * @public
 */
declare function spread<T>(obj: T, explicit?: string[]): T;
/**
 * Uses a global mutation observer to wait for a given element to appear in the
 * DOM.
 * @param childId - The id of the child node.
 * @param callback - The callback to call when the child node is found.
 *
 * @public
 */
declare function whenAvailable(childId: string, callback: (el: Element) => void, root?: Document | ShadowRoot): void;
/**
 * Given a function only 1 call will be made per call stack. All others will
 * be discarded.
 * @param fn - The function to be called once per tick.
 * @returns
 * @public
 */
declare function oncePerTick<T extends CallableFunction>(fn: T): T;
/**
 * Converts any value to a boolean value — but assumes that the default is true.
 * This is used on naked attributes like `disabled` or `required`.
 * @param value - The value to be converted to a boolean.
 * @public
 */
declare function boolGetter(value: unknown): true | undefined;

export { type FormKitDateTokens, assignDeep, boolGetter, camel, clone, cloneAny, dedupe, empty, eq, eqRegExp, escapeExp, except, extend, getAt, has, init, isObject, isPojo, isQuotedString, isRecord, kebab, nodeProps, nodeType, oncePerTick, only, parseArgs, regexForFormat, rmEscapes, setify, shallowClone, slugify, spread, token, undefine, whenAvailable };
