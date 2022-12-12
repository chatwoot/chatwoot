import { ModuleFn } from '../index';
export interface SubAPI {
    changeSettingsTab: (tab: string) => void;
    closeSettings: () => void;
    isSettingsScreenActive: () => boolean;
    navigateToSettingsPage: (path: string) => Promise<void>;
}
export interface Settings {
    lastTrackedStoryId: string;
}
export interface SubState {
    settings: Settings;
}
export declare const init: ModuleFn;
