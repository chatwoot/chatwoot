import { TransformOptions } from '@babel/core';
export declare const getStorybookBabelConfig: ({ local }?: {
    local?: boolean;
}) => TransformOptions;
export declare const getStorybookBabelDependencies: () => string[];
