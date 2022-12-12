/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
export declare type DiffOptionsColor = (arg: string) => string;
export declare type DiffOptions = {
    aAnnotation?: string;
    aColor?: DiffOptionsColor;
    aIndicator?: string;
    bAnnotation?: string;
    bColor?: DiffOptionsColor;
    bIndicator?: string;
    changeColor?: DiffOptionsColor;
    changeLineTrailingSpaceColor?: DiffOptionsColor;
    commonColor?: DiffOptionsColor;
    commonIndicator?: string;
    commonLineTrailingSpaceColor?: DiffOptionsColor;
    contextLines?: number;
    emptyFirstOrLastLinePlaceholder?: string;
    expand?: boolean;
    includeChangeCounts?: boolean;
    omitAnnotationLines?: boolean;
    patchColor?: DiffOptionsColor;
};
export declare type DiffOptionsNormalized = {
    aAnnotation: string;
    aColor: DiffOptionsColor;
    aIndicator: string;
    bAnnotation: string;
    bColor: DiffOptionsColor;
    bIndicator: string;
    changeColor: DiffOptionsColor;
    changeLineTrailingSpaceColor: DiffOptionsColor;
    commonColor: DiffOptionsColor;
    commonIndicator: string;
    commonLineTrailingSpaceColor: DiffOptionsColor;
    contextLines: number;
    emptyFirstOrLastLinePlaceholder: string;
    expand: boolean;
    includeChangeCounts: boolean;
    omitAnnotationLines: boolean;
    patchColor: DiffOptionsColor;
};
