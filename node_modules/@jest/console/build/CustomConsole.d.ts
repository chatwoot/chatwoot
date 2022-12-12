/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import { Console } from 'console';
import type { LogMessage, LogType } from './types';
declare type Formatter = (type: LogType, message: LogMessage) => string;
export default class CustomConsole extends Console {
    private _stdout;
    private _stderr;
    private _formatBuffer;
    private _counters;
    private _timers;
    private _groupDepth;
    Console: NodeJS.ConsoleConstructor;
    constructor(stdout: NodeJS.WriteStream, stderr: NodeJS.WriteStream, formatBuffer?: Formatter);
    private _log;
    private _logError;
    assert(value: unknown, message?: string | Error): asserts value;
    count(label?: string): void;
    countReset(label?: string): void;
    debug(firstArg: unknown, ...args: Array<unknown>): void;
    dir(firstArg: unknown, ...args: Array<unknown>): void;
    dirxml(firstArg: unknown, ...args: Array<unknown>): void;
    error(firstArg: unknown, ...args: Array<unknown>): void;
    group(title?: string, ...args: Array<unknown>): void;
    groupCollapsed(title?: string, ...args: Array<unknown>): void;
    groupEnd(): void;
    info(firstArg: unknown, ...args: Array<unknown>): void;
    log(firstArg: unknown, ...args: Array<unknown>): void;
    time(label?: string): void;
    timeEnd(label?: string): void;
    timeLog(label?: string, ...data: Array<unknown>): void;
    warn(firstArg: unknown, ...args: Array<unknown>): void;
    getBuffer(): undefined;
}
export {};
