/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import chalk = require('chalk');
import { DiffOptionsColor } from 'jest-diff';
import type { MatchSnapshotConfig } from './types';
declare type Chalk = chalk.Chalk;
export declare const getSnapshotColorForChalkInstance: (chalkInstance: Chalk) => DiffOptionsColor;
export declare const getReceivedColorForChalkInstance: (chalkInstance: Chalk) => DiffOptionsColor;
export declare const aSnapshotColor: DiffOptionsColor;
export declare const bReceivedColor: DiffOptionsColor;
export declare const noColor: (string: string) => string;
export declare const HINT_ARG = "hint";
export declare const SNAPSHOT_ARG = "snapshot";
export declare const PROPERTIES_ARG = "properties";
export declare const matcherHintFromConfig: ({ context: { isNot, promise }, hint, inlineSnapshot, matcherName, properties, }: MatchSnapshotConfig, isUpdatable: boolean) => string;
export declare const printExpected: (val: unknown) => string;
export declare const printReceived: (val: unknown) => string;
export declare const printPropertiesAndReceived: (properties: object, received: object, expand: boolean) => string;
export declare const printSnapshotAndReceived: (a: string, b: string, received: unknown, expand: boolean) => string;
export {};
