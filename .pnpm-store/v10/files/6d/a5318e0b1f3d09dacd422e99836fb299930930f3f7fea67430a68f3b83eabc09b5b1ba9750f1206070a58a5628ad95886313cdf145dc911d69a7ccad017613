import { S as SnapshotStateOptions, a as SnapshotMatchOptions, b as SnapshotResult, R as RawSnapshotInfo } from './rawSnapshot-BWAfsPv1.js';
export { c as SnapshotData, d as SnapshotSerializer, e as SnapshotSummary, f as SnapshotUpdateState, U as UncheckedSnapshot } from './rawSnapshot-BWAfsPv1.js';
import { S as SnapshotEnvironment } from './environment-Ddx0EDtY.js';
import { Plugin, Plugins } from '@vitest/pretty-format';

interface ParsedStack {
    method: string;
    file: string;
    line: number;
    column: number;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

interface SnapshotReturnOptions {
    actual: string;
    count: number;
    expected?: string;
    key: string;
    pass: boolean;
}
interface SaveStatus {
    deleted: boolean;
    saved: boolean;
}
declare class SnapshotState {
    testFilePath: string;
    snapshotPath: string;
    private _counters;
    private _dirty;
    private _updateSnapshot;
    private _snapshotData;
    private _initialData;
    private _inlineSnapshots;
    private _inlineSnapshotStacks;
    private _testIdToKeys;
    private _rawSnapshots;
    private _uncheckedKeys;
    private _snapshotFormat;
    private _environment;
    private _fileExists;
    private added;
    private matched;
    private unmatched;
    private updated;
    expand: boolean;
    private constructor();
    static create(testFilePath: string, options: SnapshotStateOptions): Promise<SnapshotState>;
    get environment(): SnapshotEnvironment;
    markSnapshotsAsCheckedForTest(testName: string): void;
    clearTest(testId: string): void;
    protected _inferInlineSnapshotStack(stacks: ParsedStack[]): ParsedStack | null;
    private _addSnapshot;
    save(): Promise<SaveStatus>;
    getUncheckedCount(): number;
    getUncheckedKeys(): Array<string>;
    removeUncheckedKeys(): void;
    match({ testId, testName, received, key, inlineSnapshot, isInline, error, rawSnapshot, }: SnapshotMatchOptions): SnapshotReturnOptions;
    pack(): Promise<SnapshotResult>;
}

interface AssertOptions {
    received: unknown;
    filepath: string;
    name: string;
    /**
     * Not required but needed for `SnapshotClient.clearTest` to implement test-retry behavior.
     * @default name
     */
    testId?: string;
    message?: string;
    isInline?: boolean;
    properties?: object;
    inlineSnapshot?: string;
    error?: Error;
    errorMessage?: string;
    rawSnapshot?: RawSnapshotInfo;
}
interface SnapshotClientOptions {
    isEqual?: (received: unknown, expected: unknown) => boolean;
}
declare class SnapshotClient {
    private options;
    snapshotStateMap: Map<string, SnapshotState>;
    constructor(options?: SnapshotClientOptions);
    setup(filepath: string, options: SnapshotStateOptions): Promise<void>;
    finish(filepath: string): Promise<SnapshotResult>;
    skipTest(filepath: string, testName: string): void;
    clearTest(filepath: string, testId: string): void;
    getSnapshotState(filepath: string): SnapshotState;
    assert(options: AssertOptions): void;
    assertRaw(options: AssertOptions): Promise<void>;
    clear(): void;
}

declare function stripSnapshotIndentation(inlineSnapshot: string): string;

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

declare function addSerializer(plugin: Plugin): void;
declare function getSerializers(): Plugins;

export { SnapshotClient, SnapshotMatchOptions, SnapshotResult, SnapshotState, SnapshotStateOptions, addSerializer, getSerializers, stripSnapshotIndentation };
