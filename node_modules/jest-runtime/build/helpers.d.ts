/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
export declare const createOutsideJestVmPath: (path: string) => string;
export declare const decodePossibleOutsideJestVmPath: (outsideJestVmPath: string) => string | undefined;
export declare const findSiblingsWithFileExtension: (moduleFileExtensions: Config.ProjectConfig['moduleFileExtensions'], from: Config.Path, moduleName: string) => string;
