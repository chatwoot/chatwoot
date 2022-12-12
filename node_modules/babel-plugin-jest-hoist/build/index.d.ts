/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import { Identifier } from '@babel/types';
import type { PluginObj } from '@babel/core';
declare const _default: () => PluginObj<{
    declareJestObjGetterIdentifier: () => Identifier;
    jestObjGetterIdentifier?: Identifier | undefined;
}>;
export default _default;
