/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import type { Config } from '@jest/types';
import { BaseWatchPlugin, JestHookSubscriber, UpdateConfigCallback, UsageData } from 'jest-watcher';
declare class UpdateSnapshotsPlugin extends BaseWatchPlugin {
    private _hasSnapshotFailure;
    isInternal: true;
    constructor(options: {
        stdin: NodeJS.ReadStream;
        stdout: NodeJS.WriteStream;
    });
    run(_globalConfig: Config.GlobalConfig, updateConfigAndRun: UpdateConfigCallback): Promise<boolean>;
    apply(hooks: JestHookSubscriber): void;
    getUsageInfo(): UsageData | null;
}
export default UpdateSnapshotsPlugin;
