/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type Suite from './jasmine/Suite';
declare type Options = {
    nodeComplete: (suite: TreeNode) => void;
    nodeStart: (suite: TreeNode) => void;
    queueRunnerFactory: any;
    runnableIds: Array<string>;
    tree: TreeNode;
};
export declare type TreeNode = {
    afterAllFns: Array<unknown>;
    beforeAllFns: Array<unknown>;
    disabled?: boolean;
    execute: (onComplete: () => void, enabled: boolean) => void;
    id: string;
    onException: (error: Error) => void;
    sharedUserContext: () => unknown;
    children?: Array<TreeNode>;
} & Pick<Suite, 'getResult' | 'parentSuite' | 'result' | 'markedPending'>;
export default function treeProcessor(options: Options): void;
export {};
