import type { ReleaseNotesData } from '@storybook/core-common';
export declare const getReleaseNotesFailedState: (version: string) => {
    success: boolean;
    currentVersion: string;
    showOnFirstLaunch: boolean;
};
export declare const RELEASE_NOTES_CACHE_KEY = "releaseNotesData";
export declare const getReleaseNotesData: (currentVersionToParse: string, fileSystemCache: any) => Promise<ReleaseNotesData>;
