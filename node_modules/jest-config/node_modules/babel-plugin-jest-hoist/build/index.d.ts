/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { PluginObj } from '@babel/core';
import { Identifier } from '@babel/types';
declare const _default: () => PluginObj<{
    declareJestObjGetterIdentifier: () => Identifier;
    jestObjGetterIdentifier?: Identifier;
}>;
export default _default;
