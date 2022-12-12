/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
export declare type TransformResult = {
    code: string;
    originalCode: string;
    mapCoverage?: boolean;
    sourceMapPath: string | null;
};
