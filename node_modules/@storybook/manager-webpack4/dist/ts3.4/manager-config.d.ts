import { Configuration } from 'webpack';
import { Ref, Options } from '@storybook/core-common';
export declare const getAutoRefs: (options: Options, disabledRefs?: string[]) => Promise<Ref[]>;
export declare function getManagerWebpackConfig(options: Options): Promise<Configuration>;
