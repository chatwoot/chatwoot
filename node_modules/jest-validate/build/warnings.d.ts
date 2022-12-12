/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { ValidationOptions } from './types';
export declare const unknownOptionWarning: (config: Record<string, unknown>, exampleConfig: Record<string, unknown>, option: string, options: ValidationOptions, path?: string[] | undefined) => void;
