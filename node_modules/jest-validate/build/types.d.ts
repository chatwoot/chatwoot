/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
declare type Title = {
    deprecation?: string;
    error?: string;
    warning?: string;
};
export declare type DeprecatedOptionFunc = (arg: Record<string, unknown>) => string;
export declare type DeprecatedOptions = Record<string, DeprecatedOptionFunc>;
export declare type ValidationOptions = {
    comment?: string;
    condition?: (option: unknown, validOption: unknown) => boolean;
    deprecate?: (config: Record<string, unknown>, option: string, deprecatedOptions: DeprecatedOptions, options: ValidationOptions) => boolean;
    deprecatedConfig?: DeprecatedOptions;
    error?: (option: string, received: unknown, defaultValue: unknown, options: ValidationOptions, path?: Array<string>) => void;
    exampleConfig: Record<string, unknown>;
    recursive?: boolean;
    recursiveBlacklist?: Array<string>;
    recursiveDenylist?: Array<string>;
    title?: Title;
    unknown?: (config: Record<string, unknown>, exampleConfig: Record<string, unknown>, option: string, options: ValidationOptions, path?: Array<string>) => void;
};
export {};
