/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import { Diff } from './cleanupSemantic';
import type { DiffOptions, DiffOptionsNormalized } from './types';
export declare const printDeleteLine: (line: string, isFirstOrLast: boolean, { aColor, aIndicator, changeLineTrailingSpaceColor, emptyFirstOrLastLinePlaceholder, }: DiffOptionsNormalized) => string;
export declare const printInsertLine: (line: string, isFirstOrLast: boolean, { bColor, bIndicator, changeLineTrailingSpaceColor, emptyFirstOrLastLinePlaceholder, }: DiffOptionsNormalized) => string;
export declare const printCommonLine: (line: string, isFirstOrLast: boolean, { commonColor, commonIndicator, commonLineTrailingSpaceColor, emptyFirstOrLastLinePlaceholder, }: DiffOptionsNormalized) => string;
export declare const hasCommonDiff: (diffs: Array<Diff>, isMultiline: boolean) => boolean;
export declare type ChangeCounts = {
    a: number;
    b: number;
};
export declare const countChanges: (diffs: Array<Diff>) => ChangeCounts;
export declare const printAnnotation: ({ aAnnotation, aColor, aIndicator, bAnnotation, bColor, bIndicator, includeChangeCounts, omitAnnotationLines, }: DiffOptionsNormalized, changeCounts: ChangeCounts) => string;
export declare const printDiffLines: (diffs: Array<Diff>, options: DiffOptionsNormalized) => string;
export declare const createPatchMark: (aStart: number, aEnd: number, bStart: number, bEnd: number, { patchColor }: DiffOptionsNormalized) => string;
export declare const diffStringsUnified: (a: string, b: string, options?: DiffOptions | undefined) => string;
export declare const diffStringsRaw: (a: string, b: string, cleanup: boolean) => Array<Diff>;
