import type { ThemeVars } from '@storybook/theming';
import type { ModuleFn } from '../index';
export declare type PanelPositions = 'bottom' | 'right';
export declare type ActiveTabsType = 'sidebar' | 'canvas' | 'addons';
export declare const ActiveTabs: {
    SIDEBAR: "sidebar";
    CANVAS: "canvas";
    ADDONS: "addons";
};
export interface Layout {
    initialActive: ActiveTabsType;
    isFullscreen: boolean;
    showPanel: boolean;
    panelPosition: PanelPositions;
    showNav: boolean;
    showTabs: boolean;
    showToolbar: boolean;
    /**
     * @deprecated
     */
    isToolshown?: boolean;
}
export interface UI {
    name?: string;
    url?: string;
    enableShortcuts: boolean;
    docsMode: boolean;
}
export interface SubState {
    layout: Layout;
    ui: UI;
    selectedPanel: string | undefined;
    theme: ThemeVars;
}
export interface SubAPI {
    toggleFullscreen: (toggled?: boolean) => void;
    togglePanel: (toggled?: boolean) => void;
    togglePanelPosition: (position?: PanelPositions) => void;
    toggleNav: (toggled?: boolean) => void;
    toggleToolbar: (toggled?: boolean) => void;
    setOptions: (options: any) => void;
}
export interface UIOptions {
    name?: string;
    url?: string;
    goFullScreen: boolean;
    showStoriesPanel: boolean;
    showAddonPanel: boolean;
    addonPanelInRight: boolean;
    theme?: ThemeVars;
    selectedPanel?: string;
}
export declare const focusableUIElements: {
    storySearchField: string;
    storyListMenu: string;
    storyPanelRoot: string;
};
export declare const init: ModuleFn;
