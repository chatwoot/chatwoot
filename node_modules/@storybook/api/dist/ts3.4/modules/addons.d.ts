import { ReactElement } from 'react';
import { RenderData } from '@storybook/router';
import { ModuleFn } from '../index';
import { Options } from '../store';
export declare type ViewMode = 'story' | 'info' | 'settings' | 'page' | undefined | string;
export declare enum types {
    TAB = "tab",
    PANEL = "panel",
    TOOL = "tool",
    PREVIEW = "preview",
    NOTES_ELEMENT = "notes-element"
}
export declare type Types = types | string;
export interface RenderOptions {
    active: boolean;
    key: string;
}
export interface RouteOptions {
    storyId: string;
    viewMode: ViewMode;
    location: RenderData['location'];
    path: string;
}
export interface MatchOptions {
    storyId: string;
    viewMode: ViewMode;
    location: RenderData['location'];
    path: string;
}
export interface Addon {
    title: string;
    type?: Types;
    id?: string;
    route?: (routeOptions: RouteOptions) => string;
    match?: (matchOptions: MatchOptions) => boolean;
    render: (renderOptions: RenderOptions) => ReactElement<any>;
    paramKey?: string;
    disabled?: boolean;
    hidden?: boolean;
}
export interface Collection<T = Addon> {
    [key: string]: T;
}
declare type Panels = Collection<Addon>;
declare type StateMerger<S> = (input: S) => S;
export interface SubAPI {
    getElements: <T>(type: Types) => Collection<T>;
    getPanels: () => Panels;
    getStoryPanels: () => Panels;
    getSelectedPanel: () => string;
    setSelectedPanel: (panelName: string) => void;
    setAddonState<S>(addonId: string, newStateOrMerger: S | StateMerger<S>, options?: Options): Promise<S>;
    getAddonState<S>(addonId: string): S;
}
export declare function ensurePanel(panels: Panels, selectedPanel?: string, currentPanel?: string): string;
export declare const init: ModuleFn;
export {};
