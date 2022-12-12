/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Diff } from './cleanupSemantic';
import type { DiffOptionsNormalized } from './types';
export declare const joinAlignedDiffsNoExpand: (diffs: Array<Diff>, options: DiffOptionsNormalized) => string;
export declare const joinAlignedDiffsExpand: (diffs: Array<Diff>, options: DiffOptionsNormalized) => string;
