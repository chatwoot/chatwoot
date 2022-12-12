/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { ProjectPackageJson } from './types';
declare const modifyPackageJson: ({ projectPackageJson, shouldModifyScripts, }: {
    projectPackageJson: ProjectPackageJson;
    shouldModifyScripts: boolean;
}) => string;
export default modifyPackageJson;
