/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import type { BabelTraverse, Prettier } from './types';
export declare type SnapshotStateOptions = {
    updateSnapshot: Config.SnapshotUpdateState;
    getPrettier: () => null | Prettier;
    getBabelTraverse: () => BabelTraverse;
    expand?: boolean;
};
export declare type SnapshotMatchOptions = {
    testName: string;
    received: unknown;
    key?: string;
    inlineSnapshot?: string;
    isInline: boolean;
    error?: Error;
};
declare type SnapshotReturnOptions = {
    actual: string;
    count: number;
    expected?: string;
    key: string;
    pass: boolean;
};
declare type SaveStatus = {
    deleted: boolean;
    saved: boolean;
};
export default class SnapshotState {
    private _counters;
    private _dirty;
    private _index;
    private _updateSnapshot;
    private _snapshotData;
    private _initialData;
    private _snapshotPath;
    private _inlineSnapshots;
    private _uncheckedKeys;
    private _getBabelTraverse;
    private _getPrettier;
    added: number;
    expand: boolean;
    matched: number;
    unmatched: number;
    updated: number;
    constructor(snapshotPath: Config.Path, options: SnapshotStateOptions);
    markSnapshotsAsCheckedForTest(testName: string): void;
    private _addSnapshot;
    clear(): void;
    save(): SaveStatus;
    getUncheckedCount(): number;
    getUncheckedKeys(): Array<string>;
    removeUncheckedKeys(): void;
    match({ testName, received, key, inlineSnapshot, isInline, error, }: SnapshotMatchOptions): SnapshotReturnOptions;
    fail(testName: string, _received: unknown, key?: string): string;
}
export {};
