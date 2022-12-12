/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { CrawlerOptions, FileData, InternalHasteMap } from '../types';
declare const _default: (options: CrawlerOptions) => Promise<{
    removedFiles: FileData;
    hasteMap: InternalHasteMap;
}>;
export = _default;
