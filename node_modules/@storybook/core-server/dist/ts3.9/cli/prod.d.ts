import { CommanderStatic } from 'commander';
import type { CLIOptions } from '@storybook/core-common';
export declare type ProdCliOptions = Pick<CLIOptions, 'configDir' | 'debugWebpack' | 'dll' | 'docs' | 'docsDll' | 'forceBuildPreview' | 'loglevel' | 'modern' | 'outputDir' | 'previewUrl' | 'quiet' | 'staticDir' | 'uiDll'>;
export declare function getProdCli(packageJson: {
    version: string;
    name: string;
}): CommanderStatic & ProdCliOptions;
