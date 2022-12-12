/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import { ValidationError } from 'jest-validate';
/**
 * Reporter Validation Error is thrown if the given arguments
 * within the reporter are not valid.
 *
 * This is a highly specific reporter error and in the future will be
 * merged with jest-validate. Till then, we can make use of it. It works
 * and that's what counts most at this time.
 */
export declare function createReporterError(reporterIndex: number, reporterValue: Array<Config.ReporterConfig> | string): ValidationError;
export declare function createArrayReporterError(arrayReporter: Config.ReporterConfig, reporterIndex: number, valueIndex: number, value: string | Record<string, unknown>, expectedType: string, valueName: string): ValidationError;
export declare function validateReporters(reporterConfig: Array<Config.ReporterConfig | string>): boolean;
