/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/// <reference path="../v8.d.ts" />
/// <reference types="node" />
declare type Path = string;
export declare function deserialize(buffer: Buffer): unknown;
export declare function serialize(content: unknown): Buffer;
export declare function readFileSync(filePath: Path): unknown;
export declare function writeFileSync(filePath: Path, content: unknown): void;
declare const _default: {
    deserialize: typeof deserialize;
    readFileSync: typeof readFileSync;
    serialize: typeof serialize;
    writeFileSync: typeof writeFileSync;
};
export default _default;
