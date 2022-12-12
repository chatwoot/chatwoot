/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
declare type ResolveOptions = {
    rootDir: Config.Path;
    key: string;
    filePath: Config.Path;
    optional?: boolean;
};
export declare const BULLET: string;
export declare const DOCUMENTATION_NOTE: string;
export declare const resolve: (resolver: string | null | undefined, { key, filePath, rootDir, optional }: ResolveOptions) => string;
export declare const escapeGlobCharacters: (path: Config.Path) => Config.Glob;
export declare const replaceRootDirInPath: (rootDir: Config.Path, filePath: Config.Path) => string;
declare type OrArray<T> = T | Array<T>;
declare type ReplaceRootDirConfigObj = Record<string, Config.Path>;
declare type ReplaceRootDirConfigValues = OrArray<ReplaceRootDirConfigObj> | OrArray<RegExp> | OrArray<Config.Path>;
export declare const _replaceRootDirTags: <T extends ReplaceRootDirConfigValues>(rootDir: Config.Path, config: T) => T;
export declare const resolveWithPrefix: (resolver: string | undefined | null, { filePath, humanOptionName, optionName, prefix, rootDir, }: {
    filePath: string;
    humanOptionName: string;
    optionName: string;
    prefix: string;
    rootDir: Config.Path;
}) => string;
/**
 * Finds the test environment to use:
 *
 * 1. looks for jest-environment-<name> relative to project.
 * 1. looks for jest-environment-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */
export declare const getTestEnvironment: ({ rootDir, testEnvironment: filePath, }: {
    rootDir: Config.Path;
    testEnvironment: string;
}) => string;
/**
 * Finds the watch plugins to use:
 *
 * 1. looks for jest-watch-<name> relative to project.
 * 1. looks for jest-watch-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */
export declare const getWatchPlugin: (resolver: string | undefined | null, { filePath, rootDir }: {
    filePath: string;
    rootDir: Config.Path;
}) => string;
/**
 * Finds the runner to use:
 *
 * 1. looks for jest-runner-<name> relative to project.
 * 1. looks for jest-runner-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */
export declare const getRunner: (resolver: string | undefined | null, { filePath, rootDir }: {
    filePath: string;
    rootDir: Config.Path;
}) => string;
declare type JSONString = string & {
    readonly $$type: never;
};
export declare const isJSONString: (text?: string | JSONString | undefined) => text is JSONString;
export declare const getSequencer: (resolver: string | undefined | null, { filePath, rootDir }: {
    filePath: string;
    rootDir: Config.Path;
}) => string;
export {};
