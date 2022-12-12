// Type definitions for memoizerific 1.11.2
// Project: https://github.com/thinkloop/memoizerific
// Definitions by: https://github.com/3af

// inspired by https://stackoverflow.com/a/43382807

declare module "memoizerific" {
    export = memoizerific;
}

type memoize = <R, T extends (...args: any[]) => R>(fn: T) => T;

declare function memoizerific(cacheSize: number): memoize;
