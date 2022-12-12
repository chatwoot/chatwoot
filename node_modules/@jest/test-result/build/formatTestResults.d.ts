/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { AggregatedResult, CodeCoverageFormatter, CodeCoverageReporter, FormattedTestResults } from './types';
export default function formatTestResults(results: AggregatedResult, codeCoverageFormatter?: CodeCoverageFormatter, reporter?: CodeCoverageReporter): FormattedTestResults;
