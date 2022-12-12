import { TransformOptions } from '@babel/core';
export declare const loadCustomBabelConfig: (configDir: string, getDefaultConfig: () => TransformOptions) => Promise<TransformOptions>;
