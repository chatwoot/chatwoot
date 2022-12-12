/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
declare type Matcher = (str: Config.Path) => boolean;
/**
 * Converts a list of globs into a function that matches a path against the
 * globs.
 *
 * Every time micromatch is called, it will parse the glob strings and turn
 * them into regexp instances. Instead of calling micromatch repeatedly with
 * the same globs, we can use this function which will build the micromatch
 * matchers ahead of time and then have an optimized path for determining
 * whether an individual path matches.
 *
 * This function is intended to match the behavior of `micromatch()`.
 *
 * @example
 * const isMatch = globsToMatcher(['*.js', '!*.test.js']);
 * isMatch('pizza.js'); // true
 * isMatch('pizza.test.js'); // false
 */
export default function globsToMatcher(globs: Array<Config.Glob>): Matcher;
export {};
