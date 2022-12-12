/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
import type { Expect, MatcherState, MatchersObject } from './types';
export declare const INTERNAL_MATCHER_FLAG: unique symbol;
export declare const getState: () => MatcherState;
export declare const setState: (state: Partial<MatcherState>) => void;
export declare const getMatchers: () => MatchersObject;
export declare const setMatchers: (matchers: MatchersObject, isInternal: boolean, expect: Expect) => void;
