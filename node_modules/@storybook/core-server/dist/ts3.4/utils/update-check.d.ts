import { VersionCheck } from '@storybook/core-common';
export declare const updateCheck: (version: string) => Promise<VersionCheck>;
export declare function createUpdateMessage(updateInfo: VersionCheck, version: string): string;
