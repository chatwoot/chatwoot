/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
import * as constants from './constants';
export { getTestEnvironment, isJSONString } from './utils';
export { default as normalize } from './normalize';
export { default as deprecationEntries } from './Deprecated';
export { replaceRootDirInPath } from './utils';
export { default as defaults } from './Defaults';
export { default as descriptions } from './Descriptions';
export { constants };
declare type ReadConfig = {
    configPath: Config.Path | null | undefined;
    globalConfig: Config.GlobalConfig;
    hasDeprecationWarnings: boolean;
    projectConfig: Config.ProjectConfig;
};
export declare function readConfig(argv: Config.Argv, packageRootOrConfig: Config.Path | Config.InitialOptions, skipArgvConfigOption?: boolean, parentConfigPath?: Config.Path | null, projectIndex?: number): Promise<ReadConfig>;
export declare function readConfigs(argv: Config.Argv, projectPaths: Array<Config.Path>): Promise<{
    globalConfig: Config.GlobalConfig;
    configs: Array<Config.ProjectConfig>;
    hasDeprecationWarnings: boolean;
}>;
