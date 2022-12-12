/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
declare type ReplaceableForEachCallBack = (value: unknown, key: unknown, object: unknown) => void;
export default class Replaceable {
    object: any;
    type: string;
    constructor(object: any);
    static isReplaceable(obj1: unknown, obj2: unknown): boolean;
    forEach(cb: ReplaceableForEachCallBack): void;
    get(key: any): any;
    set(key: any, value: any): void;
}
export {};
