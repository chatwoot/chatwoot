/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Options } from 'yargs';
import type { Config } from '@jest/types';
import type { DeprecatedOptions } from './types';
export declare const DOCUMENTATION_NOTE: string;
export default function validateCLIOptions(argv: Config.Argv, options: {
    deprecationEntries: DeprecatedOptions;
    [s: string]: Options;
}, rawArgv?: Array<string>): boolean;
