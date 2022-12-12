import * as webpack from 'webpack';
import { AsyncSeriesHook, SyncHook } from 'tapable';
export declare type ForkTsCheckerHooks = 'serviceBeforeStart' | 'cancel' | 'serviceStartError' | 'waiting' | 'serviceStart' | 'receive' | 'serviceOutOfMemory' | 'emit' | 'done';
export declare function getForkTsCheckerWebpackPluginHooks(compiler: webpack.Compiler): Record<ForkTsCheckerHooks, SyncHook<any, any, any> | AsyncSeriesHook<any, any, any>>;
