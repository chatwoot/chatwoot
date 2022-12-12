/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Diff } from './cleanupSemantic';
import type { DiffOptionsColor } from './types';
declare const getAlignedDiffs: (diffs: Array<Diff>, changeColor: DiffOptionsColor) => Array<Diff>;
export default getAlignedDiffs;
