/// <reference types="node" />
/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
/// <reference types="node" />
import { EventEmitter } from 'events';
import { Matcher } from 'anymatch';
/**
 * Export `FSEventsWatcher` class.
 * Watches `dir`.
 */
declare class FSEventsWatcher extends EventEmitter {
    readonly root: string;
    readonly ignored?: Matcher;
    readonly glob: Array<string>;
    readonly dot: boolean;
    readonly hasIgnore: boolean;
    readonly doIgnore: (path: string) => boolean;
    readonly fsEventsWatchStopper: () => Promise<void>;
    private _tracked;
    static isSupported(): boolean;
    private static normalizeProxy;
    private static recReaddir;
    constructor(dir: string, opts: {
        root: string;
        ignored?: Matcher;
        glob: string | Array<string>;
        dot: boolean;
    });
    /**
     * End watching.
     */
    close(callback?: () => void): void;
    private isFileIncluded;
    private handleEvent;
    /**
     * Emit events.
     */
    private _emit;
}
export = FSEventsWatcher;
