/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { SnapshotData } from './types';
export declare const SNAPSHOT_VERSION = "1";
export declare const SNAPSHOT_GUIDE_LINK = "https://goo.gl/fbAQLP";
export declare const SNAPSHOT_VERSION_WARNING: string;
export declare const testNameToKey: (testName: Config.Path, count: number) => string;
export declare const keyToTestName: (key: string) => string;
export declare const getSnapshotData: (snapshotPath: Config.Path, update: Config.SnapshotUpdateState) => {
    data: SnapshotData;
    dirty: boolean;
};
export declare const addExtraLineBreaks: (string: string) => string;
export declare const removeExtraLineBreaks: (string: string) => string;
export declare const removeLinesBeforeExternalMatcherTrap: (stack: string) => string;
export declare const serialize: (val: unknown, indent?: number) => string;
export declare const minify: (val: unknown) => string;
export declare const deserializeString: (stringified: string) => string;
export declare const escapeBacktickString: (str: string) => string;
export declare const ensureDirectoryExists: (filePath: Config.Path) => void;
export declare const saveSnapshotFile: (snapshotData: SnapshotData, snapshotPath: Config.Path) => void;
export declare const deepMerge: (target: any, source: any) => any;
