/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
interface ErrorWithCodeFrame extends Error {
    codeFrame?: string;
}
export default function handlePotentialSyntaxError(e: ErrorWithCodeFrame): ErrorWithCodeFrame;
export declare function enhanceUnexpectedTokenMessage(e: Error): Error;
export {};
