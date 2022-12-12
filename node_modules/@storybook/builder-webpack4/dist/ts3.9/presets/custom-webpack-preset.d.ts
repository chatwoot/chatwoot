import * as webpackReal from 'webpack';
import type { Options } from '@storybook/core-common';
import type { Configuration } from 'webpack';
export declare function webpack(config: Configuration, options: Options): Promise<any>;
export declare const webpackInstance: () => Promise<typeof webpackReal>;
export declare const webpackVersion: () => Promise<string>;
