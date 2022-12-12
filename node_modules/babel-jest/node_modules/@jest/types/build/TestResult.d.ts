/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
export declare type Milliseconds = number;
declare type Status = 'passed' | 'failed' | 'skipped' | 'pending' | 'todo' | 'disabled';
declare type Callsite = {
    column: number;
    line: number;
};
export declare type AssertionResult = {
    ancestorTitles: Array<string>;
    duration?: Milliseconds | null;
    failureMessages: Array<string>;
    fullName: string;
    invocations?: number;
    location?: Callsite | null;
    numPassingAsserts: number;
    status: Status;
    title: string;
};
export declare type SerializableError = {
    code?: unknown;
    message: string;
    stack: string | null | undefined;
    type?: string;
};
export {};
