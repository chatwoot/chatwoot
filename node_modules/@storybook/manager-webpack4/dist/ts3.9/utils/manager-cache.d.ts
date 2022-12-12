import type { Options } from '@storybook/core-common';
import webpack from 'webpack';
export declare const useManagerCache: (cacheKey: string, options: Options, managerConfig: webpack.Configuration) => Promise<boolean>;
export declare const clearManagerCache: (cacheKey: string, options: Options) => Promise<boolean>;
