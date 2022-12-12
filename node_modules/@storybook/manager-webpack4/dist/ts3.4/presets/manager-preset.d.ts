import { Configuration } from 'webpack';
import { Options, ManagerWebpackOptions } from '@storybook/core-common';
export declare function managerWebpack(_: Configuration, { configDir, configType, docsMode, entries, refs, outputDir, previewUrl, versionCheck, releaseNotesData, presets, modern, features, serverChannelUrl, }: Options & ManagerWebpackOptions): Promise<Configuration>;
export declare function managerEntries(installedAddons: string[], options: {
    managerEntry: string;
    configDir: string;
    modern?: boolean;
}): Promise<string[]>;
