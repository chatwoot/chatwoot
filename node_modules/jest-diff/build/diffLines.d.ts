/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Diff } from './cleanupSemantic';
import type { DiffOptions } from './types';
export declare const diffLinesUnified: (aLines: Array<string>, bLines: Array<string>, options?: DiffOptions | undefined) => string;
export declare const diffLinesUnified2: (aLinesDisplay: Array<string>, bLinesDisplay: Array<string>, aLinesCompare: Array<string>, bLinesCompare: Array<string>, options?: DiffOptions | undefined) => string;
export declare const diffLinesRaw: (aLines: Array<string>, bLines: Array<string>) => Array<Diff>;
