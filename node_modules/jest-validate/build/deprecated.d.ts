/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { DeprecatedOptions, ValidationOptions } from './types';
export declare const deprecationWarning: (config: Record<string, unknown>, option: string, deprecatedOptions: DeprecatedOptions, options: ValidationOptions) => boolean;
