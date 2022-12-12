/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Frame } from 'jest-message-util';
import type { BabelTraverse, Prettier } from './types';
export declare type InlineSnapshot = {
    snapshot: string;
    frame: Frame;
};
export declare function saveInlineSnapshots(snapshots: Array<InlineSnapshot>, prettier: Prettier | null, babelTraverse: BabelTraverse): void;
