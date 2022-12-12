/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { DIFF_DELETE, DIFF_EQUAL, DIFF_INSERT, Diff } from './cleanupSemantic';
import { diffLinesRaw, diffLinesUnified, diffLinesUnified2 } from './diffLines';
import { diffStringsRaw, diffStringsUnified } from './printDiffs';
import type { DiffOptions } from './types';
export type { DiffOptions, DiffOptionsColor } from './types';
export { diffLinesRaw, diffLinesUnified, diffLinesUnified2 };
export { diffStringsRaw, diffStringsUnified };
export { DIFF_DELETE, DIFF_EQUAL, DIFF_INSERT, Diff };
declare function diff(a: any, b: any, options?: DiffOptions): string | null;
export default diff;
