/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import prettyFormat = require('pretty-format');
export declare const addSerializer: (plugin: prettyFormat.Plugin) => void;
export declare const getSerializers: () => import("pretty-format/build/types").Plugins;
