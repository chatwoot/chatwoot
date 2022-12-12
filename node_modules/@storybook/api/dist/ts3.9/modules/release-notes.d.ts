import { ModuleFn } from '../index';
export interface ReleaseNotes {
    success?: boolean;
    currentVersion?: string;
    showOnFirstLaunch?: boolean;
}
export interface SubAPI {
    releaseNotesVersion: () => string;
    setDidViewReleaseNotes: () => void;
    showReleaseNotesOnLaunch: () => boolean;
}
export interface SubState {
    releaseNotesViewed: string[];
}
export declare const init: ModuleFn;
