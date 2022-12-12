/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Expect, MatcherState as JestMatcherState, Matchers as MatcherInterface } from './types';
declare const expectExport: Expect;
declare namespace expectExport {
    type MatcherState = JestMatcherState;
    interface Matchers<R> extends MatcherInterface<R> {
    }
}
export = expectExport;
