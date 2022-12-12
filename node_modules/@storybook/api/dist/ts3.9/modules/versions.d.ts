import { ModuleFn } from '../index';
export interface Version {
    version: string;
    info?: {
        plain: string;
    };
    [key: string]: any;
}
export interface UnknownEntries {
    [key: string]: {
        [key: string]: any;
    };
}
export interface Versions {
    latest?: Version;
    next?: Version;
    current?: Version;
}
export interface SubState {
    versions: Versions & UnknownEntries;
    lastVersionCheck: number;
    dismissedVersionNotification: undefined | string;
}
export interface SubAPI {
    getCurrentVersion: () => Version;
    getLatestVersion: () => Version;
    versionUpdateAvailable: () => boolean;
}
export declare const init: ModuleFn;
