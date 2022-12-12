import { StorybookConfig, PackageJson } from '@storybook/core-common';
import { StorybookMetadata } from './types';
export declare const metaFrameworks: Record<string, string>;
export declare const computeStorybookMetadata: ({ packageJson, mainConfig, }: {
    packageJson: PackageJson;
    mainConfig: StorybookConfig & Record<string, any>;
}) => Promise<StorybookMetadata>;
export declare const getStorybookMetadata: (_configDir: string) => Promise<StorybookMetadata>;
