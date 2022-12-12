/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
export default class ModuleNotFoundError extends Error {
    code: string;
    hint?: string;
    requireStack?: Array<Config.Path>;
    siblingWithSimilarExtensionFound?: boolean;
    moduleName?: string;
    private _originalMessage?;
    constructor(message: string, moduleName?: string);
    buildMessage(rootDir: Config.Path): void;
    static duckType(error: ModuleNotFoundError): ModuleNotFoundError;
}
