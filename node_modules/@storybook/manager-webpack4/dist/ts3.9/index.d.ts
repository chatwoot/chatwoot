import webpack from 'webpack';
import type { Stats, Configuration } from 'webpack';
import type { Builder, Options } from '@storybook/core-common';
declare type WebpackBuilder = Builder<Configuration, Stats>;
declare type BuilderStartOptions = Partial<Parameters<WebpackBuilder['start']>['0']>;
export declare const WEBPACK_VERSION = "4";
export declare const getConfig: WebpackBuilder['getConfig'];
export declare const makeStatsFromError: (err: string) => webpack.Stats;
export declare const executor: {
    get: (options: Options) => Promise<typeof webpack>;
};
export declare const bail: WebpackBuilder['bail'];
export declare const start: (options: BuilderStartOptions) => Promise<unknown>;
export declare const build: (options: BuilderStartOptions) => Promise<unknown>;
export declare const corePresets: WebpackBuilder['corePresets'];
export declare const overridePresets: WebpackBuilder['overridePresets'];
export {};
