/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Config } from '@jest/types';
import expectationResultFactory from '../expectationResultFactory';
import type { QueueableFn } from '../queueRunner';
import type Spec from './Spec';
export declare type SuiteResult = {
    id: string;
    description: string;
    fullName: string;
    failedExpectations: Array<ReturnType<typeof expectationResultFactory>>;
    testPath: Config.Path;
    status?: string;
};
export declare type Attributes = {
    id: string;
    parentSuite?: Suite;
    description: string;
    throwOnExpectationFailure?: boolean;
    getTestPath: () => Config.Path;
};
export default class Suite {
    id: string;
    parentSuite?: Suite;
    description: string;
    throwOnExpectationFailure: boolean;
    beforeFns: Array<QueueableFn>;
    afterFns: Array<QueueableFn>;
    beforeAllFns: Array<QueueableFn>;
    afterAllFns: Array<QueueableFn>;
    disabled: boolean;
    children: Array<Suite | Spec>;
    result: SuiteResult;
    sharedContext?: object;
    markedPending: boolean;
    markedTodo: boolean;
    isFocused: boolean;
    constructor(attrs: Attributes);
    getFullName(): string;
    disable(): void;
    pend(_message?: string): void;
    beforeEach(fn: QueueableFn): void;
    beforeAll(fn: QueueableFn): void;
    afterEach(fn: QueueableFn): void;
    afterAll(fn: QueueableFn): void;
    addChild(child: Suite | Spec): void;
    status(): "failed" | "pending" | "disabled" | "finished";
    isExecutable(): boolean;
    canBeReentered(): boolean;
    getResult(): SuiteResult;
    sharedUserContext(): object;
    clonedSharedUserContext(): object;
    onException(...args: Parameters<Spec['onException']>): void;
    addExpectationResult(...args: Parameters<Spec['addExpectationResult']>): void;
    execute(..._args: Array<any>): void;
}
