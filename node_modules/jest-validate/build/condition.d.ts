/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
export declare function getValues<T = unknown>(validOption: T): Array<T>;
export declare function validationCondition(option: unknown, validOption: unknown): boolean;
export declare function multipleValidOptions<T extends Array<unknown>>(...args: T): T[number];
