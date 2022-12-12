/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference types="node" />
import { Console } from 'console';
import type { ConsoleBuffer, LogMessage, LogType } from './types';
export default class BufferedConsole extends Console {
    private _buffer;
    private _counters;
    private _timers;
    private _groupDepth;
    Console: NodeJS.ConsoleConstructor;
    constructor();
    static write(buffer: ConsoleBuffer, type: LogType, message: LogMessage, level?: number | null): ConsoleBuffer;
    private _log;
    assert(value: unknown, message?: string | Error): void;
    count(label?: string): void;
    countReset(label?: string): void;
    debug(firstArg: unknown, ...rest: Array<unknown>): void;
    dir(firstArg: unknown, ...rest: Array<unknown>): void;
    dirxml(firstArg: unknown, ...rest: Array<unknown>): void;
    error(firstArg: unknown, ...rest: Array<unknown>): void;
    group(title?: string, ...rest: Array<unknown>): void;
    groupCollapsed(title?: string, ...rest: Array<unknown>): void;
    groupEnd(): void;
    info(firstArg: unknown, ...rest: Array<unknown>): void;
    log(firstArg: unknown, ...rest: Array<unknown>): void;
    time(label?: string): void;
    timeEnd(label?: string): void;
    timeLog(label?: string, ...data: Array<unknown>): void;
    warn(firstArg: unknown, ...rest: Array<unknown>): void;
    getBuffer(): ConsoleBuffer | undefined;
}
