import { ReactElement } from 'react';
import { Channel } from '@storybook/channels';
import { API } from '@storybook/api';
import { RenderData as RouterData } from '@storybook/router';
import { ThemeVars } from '@storybook/theming';
import { Types } from './types';
export { Channel };
export interface RenderOptions {
    active?: boolean;
    key?: string;
}
export interface Addon {
    title: (() => string) | string;
    type?: Types;
    id?: string;
    route?: (routeOptions: RouterData) => string;
    match?: (matchOptions: RouterData) => boolean;
    render: (renderOptions: RenderOptions) => ReactElement<any>;
    paramKey?: string;
    disabled?: boolean;
    hidden?: boolean;
}
export declare type Loader = (api: API) => void;
export interface Collection {
    [key: string]: Addon;
}
interface ToolbarConfig {
    hidden?: boolean;
}
export interface Config {
    theme?: ThemeVars;
    toolbar?: {
        [id: string]: ToolbarConfig;
    };
    [key: string]: any;
}
export declare class AddonStore {
    constructor();
    private loaders;
    private elements;
    private config;
    private channel;
    private serverChannel;
    private promise;
    private resolve;
    getChannel: () => Channel;
    getServerChannel: () => Channel;
    ready: () => Promise<Channel>;
    hasChannel: () => boolean;
    hasServerChannel: () => boolean;
    setChannel: (channel: Channel) => void;
    setServerChannel: (channel: Channel) => void;
    getElements: (type: Types) => Collection;
    addPanel: (name: string, options: Addon) => void;
    add: (name: string, addon: Addon) => void;
    setConfig: (value: Config) => void;
    getConfig: () => Config;
    register: (name: string, registerCallback: (api: API) => void) => void;
    loadAddons: (api: any) => void;
}
export declare const addons: AddonStore;
